//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ISurvivor.sol";
import "./libraries/SurvivorRole.sol";
import "./libraries/SurvivorVars.sol";
import "./libraries/SurvivorMap.sol";

contract Survivor is ISurvivor, AccessControl {
    using SurvivorMap for SurvivorMap.MapVars;
    using SurvivorRole for SurvivorRole.Role;
    using SurvivorVars for SurvivorVars.Vars;

    bytes32 public constant YINJA_GAME_MANAGER =
        keccak256("YINJA_GAME_MANAGER");

    modifier isAuthorizedForToken(address account, uint256 tokenId) {
        require(
            IERC721(yinja).ownerOf(tokenId) == account,
            "YINJA Survivor: Not approved"
        );
        _;
    }

    modifier checkRoleStatus(uint256 tokenId) {
        checkRoleStatusAndSet(tokenId);
        _;
    }

    /// user role and coordinate
    mapping(bytes32 => uint256) public userCoordinates;
    mapping(uint256 => SurvivorRole.Role) public userRoles;

    /// yinja NFT address and survivorVars
    SurvivorVars.Vars public survivorVars;
    SurvivorMap.MapVars public mapVars;
    address public yinja;

    constructor(
        uint64 _MAP_WIDTH,
        uint64 _MAP_HEIGHT,
        uint64 _AREA_WIDTH,
        uint64 _AREA_HEIGHT,
        uint256 _totalSurvivors,
        address _yinja
    ) {
        yinja = _yinja;
        mapVars = SurvivorMap.MapVars({
            MAP_WIDTH: _MAP_WIDTH,
            MAP_HEIGHT: _MAP_HEIGHT,
            AREA_WIDTH: _AREA_WIDTH,
            AREA_HEIGHT: _AREA_HEIGHT
        });
        survivorVars = SurvivorVars.Vars({
            prizePool: 0,
            lastAirStrikeTimestamp: 0,
            lastAirStrikeNumber: 0,
            joinedPlayers: 0,
            airJoinedPlayers: 0,
            totalSurvivors: _totalSurvivors,
            remainSurvivors: _totalSurvivors,
            salt: uint256(keccak256("YINJA Survivor")),
            status: SurvivorVars.Status.PREPARE
        });
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(YINJA_GAME_MANAGER, msg.sender);
    }

    function checkRoleStatusAndSet(uint256 tokenId) internal {
        if (
            survivorVars.remainSurvivors == 1 &&
            !userRoles[tokenId].isDismissed()
        ) {
            if (!userRoles[tokenId].isWinner()) {
                userRoles[tokenId].setWinner();
            }
            if (!survivorVars.isEndStatus()) {
                survivorVars.status = SurvivorVars.Status.END;
            }
        }
    }

    function setGameStatus(SurvivorVars.Status _status)
        external
        onlyRole(YINJA_GAME_MANAGER)
    {
        survivorVars.status = _status;
        emit GameStatusChange(_status);
    }

    function setAirStrikeNumber(uint256 lastAirStrikeNumber)
        public
        onlyRole(YINJA_GAME_MANAGER)
    {
        survivorVars.lastAirStrikeNumber = lastAirStrikeNumber;
    }

    function setAirJoinPlayers(JoinVars[] memory vars)
        external
        onlyRole(YINJA_GAME_MANAGER)
        returns (uint256 count)
    {
        for (uint256 idx = 0; idx < vars.length; idx++) {
            if (
                survivorVars.airJoinedPlayers + survivorVars.joinedPlayers >
                survivorVars.totalSurvivors
            ) continue;
            else if (getPositions(vars[idx].x, vars[idx].y) != 0) continue;
            else if (vars[idx].country < 0 || vars[idx].country > 232) continue;
            else if (getPositions(vars[idx].x, vars[idx].y) != 0) continue;
            else if (
                userRoles[vars[idx].yinjaId].attributes.healthPoint != 0 ||
                userRoles[vars[idx].yinjaId].isJoin()
            ) continue;
            else {
                joinRole(vars[idx]);
                survivorVars.airJoinedPlayers += 1;
                count++;
                emit AirJoinPlayer(
                    vars[idx].yinjaId,
                    vars[idx].x,
                    vars[idx].y,
                    vars[idx].country
                );
            }
        }
    }

    function checkHealthPoint(uint256 yinjaId) internal {
        if (userRoles[yinjaId].attributes.healthPoint == 0) {
            userRoles[yinjaId].setDead();
            survivorVars.remainSurvivors -= 1;
        }
    }

    function getGameStage() public view returns (SurvivorVars.Stage) {
        uint256 remainSurvivors = survivorVars.remainSurvivors;
        uint256 totalSurvivors = survivorVars.totalSurvivors;
        if (survivorVars.isPrepareStatus()) {
            return SurvivorVars.Stage.ZERO;
        } else {
            if ((100 * remainSurvivors) / totalSurvivors > 80) {
                return SurvivorVars.Stage.ONE;
            } else if ((100 * remainSurvivors) / totalSurvivors > 60) {
                return SurvivorVars.Stage.TWO;
            } else if ((100 * remainSurvivors) / totalSurvivors > 40) {
                return SurvivorVars.Stage.THREE;
            } else if ((100 * remainSurvivors) / totalSurvivors > 20) {
                return SurvivorVars.Stage.FOUR;
            } else {
                require(
                    survivorVars.isStartStatus() || survivorVars.isEndStatus(),
                    "YINJA Survivor: invalid status"
                );
                return SurvivorVars.Stage.FIVE;
            }
        }
    }

    function getLevelUpCost(uint64 levelUpCount, SurvivorVars.Stage stage)
        public
        view
        returns (uint256)
    {
        if (!survivorVars.isStartStatus()) {
            return uint256(0);
        }
        uint256 denominator = 10**levelUpCount;
        uint256 baseCost = 0.05 ether;
        if (stage == SurvivorVars.Stage.ONE) {
            return (12**levelUpCount * baseCost) / denominator;
        } else if (stage == SurvivorVars.Stage.TWO) {
            return (14**levelUpCount * baseCost) / denominator;
        } else if (stage == SurvivorVars.Stage.THREE) {
            return (16**levelUpCount * baseCost) / denominator;
        } else if (stage == SurvivorVars.Stage.FOUR) {
            return (18**levelUpCount * baseCost) / denominator;
        } else {
            return 2**levelUpCount * baseCost;
        }
    }

    function joinRole(JoinVars memory vars) internal {
        SurvivorRole.Role memory yinjaRole;
        yinjaRole.attributes.level = 0;
        yinjaRole.attributes.healthPoint = 20;
        yinjaRole.attributes.shieldExpired = 0;
        yinjaRole.attributes.airStrikeExpired = 0;
        yinjaRole.attributes.country = vars.country;
        yinjaRole.attributes.state = 1; // join
        yinjaRole.positions.x = vars.x;
        yinjaRole.positions.y = vars.y;
        yinjaRole.positions.areaNumber = mapVars.getAreaNumber(vars.x, vars.y);
        yinjaRole.prize = 0;
        yinjaRole.statistic.levelUpCount = 0;
        yinjaRole.statistic.moveCount = 0;
        yinjaRole.statistic.attackCount = 0;
        yinjaRole.statistic.airStrkieCount = 0;
        yinjaRole.statistic.hitedCount = 0;

        // yinjaRoles update
        userRoles[vars.yinjaId] = yinjaRole;

        // userCoordinates update
        userCoordinates[userRoles[vars.yinjaId].getPositionsKey()] = vars
            .yinjaId;
    }

    function join(JoinVars memory vars)
        external
        isAuthorizedForToken(msg.sender, vars.yinjaId)
    {
        require(survivorVars.isPrepareStatus(), "Survivor: only prepare join");
        require(
            getPositions(vars.x, vars.y) == 0,
            "Survivor: positions already taken"
        );
        require(
            userRoles[vars.yinjaId].attributes.healthPoint == 0 &&
                !userRoles[vars.yinjaId].isJoin(),
            "Survivor: already join"
        );
        require(
            vars.country >= 0 && vars.country <= 232,
            "Survivor: invalid country id"
        );

        // JoinRole
        joinRole(vars);

        // survivorVars update
        survivorVars.joinedPlayers += 1;

        emit JoinPlayer(vars.yinjaId, vars.x, vars.y, vars.country);
    }

    function levelUp(uint256 yinjaId)
        external
        payable
        isAuthorizedForToken(msg.sender, yinjaId)
        checkRoleStatus(yinjaId)
    {
        require(survivorVars.isStartStatus(), "YINJA Survivor: invalid status");
        uint256 minCost = getLevelUpCost(
            userRoles[yinjaId].statistic.levelUpCount,
            getGameStage()
        );
        require(msg.value == minCost, "YINJA Survivor: minimum cost");

        userRoles[yinjaId].attributes.level += 1;
        userRoles[yinjaId].attributes.healthPoint += 10;
        userRoles[yinjaId].statistic.levelUpCount += 1;
        survivorVars.prizePool += (msg.value * 80) / 100;

        emit LevelUp(yinjaId, minCost);
    }

    function confirmHit(
        uint64 x,
        uint64 y,
        uint256 yinjaId
    )
        external
        payable
        isAuthorizedForToken(msg.sender, yinjaId)
        checkRoleStatus(yinjaId)
    {
        require(survivorVars.isStartStatus(), "YINJA Survivor: invalid status");
        uint256 targetId = userCoordinates[keccak256(abi.encodePacked(x, y))];
        require(
            targetId != 0 &&
                !userRoles[yinjaId].isDismissed() &&
                !userRoles[targetId].isDismissed(),
            "YINJA Survivor: user dismiss"
        );
        require(targetId != yinjaId, "YINJA Survivor: cannot attack yourself");
        SurvivorRole.Role storage attackRole = userRoles[yinjaId];
        SurvivorRole.Role storage targetRole = userRoles[targetId];
        require(
            targetRole.attributes.shieldExpired == 0 ||
                (block.timestamp > targetRole.attributes.shieldExpired &&
                    targetRole.attributes.shieldExpired != 0),
            "YINJA Survivor: shield can not be attacked"
        );
        {
            // handle targetRole
            targetRole.attributes.healthPoint = targetRole
                .attributes
                .healthPoint >= 10
                ? targetRole.attributes.healthPoint - 10
                : 0;
            checkHealthPoint(targetId);
            if (targetRole.attributes.healthPoint == 0) {
                // remove from coordinate
                userCoordinates[keccak256(abi.encodePacked(x, y))] = 0;
                if (survivorVars.isOpenBounsPrize()) {
                    uint256 bounsPrize = (survivorVars.getEvacuatePrize() *
                        50) / 100;
                    attackRole.prize += bounsPrize;
                    survivorVars.prizePool -= bounsPrize;
                }
                checkRoleStatusAndSet(yinjaId);
                emit KillCharacter(yinjaId, targetId);
            }
            if (survivorVars.isFinishedGame()) return;
            if (targetRole.attributes.healthPoint > 0) {
                targetRole.attributes.shieldExpired = block.timestamp + 4 hours;
            }
        }
        {
            // handle attackRole
            attackRole.attributes.healthPoint = attackRole
                .attributes
                .healthPoint >= 8
                ? attackRole.attributes.healthPoint - 8
                : 0;
            checkHealthPoint(yinjaId);
            if (attackRole.attributes.healthPoint == 0) {
                userCoordinates[attackRole.getPositionsKey()] = 0;
                if (survivorVars.isOpenBounsPrize()) {
                    uint256 bounsPrize = (survivorVars.getEvacuatePrize() *
                        50) / 100;
                    targetRole.prize += bounsPrize;
                    survivorVars.prizePool -= bounsPrize;
                }
                checkRoleStatusAndSet(targetId);
                emit KillCharacter(targetId, yinjaId);
            }
        }
        attackRole.prize += 0.01 ether; // confirm hit prize
        attackRole.statistic.attackCount += 1;
        attackRole.attributes.shieldExpired = 0;
        survivorVars.prizePool -= 0.01 ether;
        targetRole.statistic.hitedCount += 1;

        emit ConfirmHit(yinjaId, targetId);
    }

    function move(
        uint64 x,
        uint64 y,
        uint256 yinjaId
    )
        external
        payable
        isAuthorizedForToken(msg.sender, yinjaId)
        checkRoleStatus(yinjaId)
    {
        require(survivorVars.isStartStatus(), "YINJA Survivor: invalid status");
        require(
            !userRoles[yinjaId].isDismissed(),
            "YINJA Survivor: user dismiss"
        );
        require(
            block.timestamp > userRoles[yinjaId].attributes.airStrikeExpired &&
                userRoles[yinjaId].attributes.airStrikeExpired != 0,
            "YINJA Survivor: can not move"
        );
        require(
            x > 0 && x < mapVars.MAP_WIDTH && y > 0 && y < mapVars.MAP_HEIGHT,
            "YINJA Survivor: out of map"
        );
        require(getPositions(x, y) == 0, "YINJA Survivor: already taken");
        require(msg.value == 0.01 ether, "YINJA Survivor: minimum move cost");
        require(
            userCoordinates[userRoles[yinjaId].getPositionsKey()] == yinjaId,
            "YINJA Survivor: account positions"
        );
        userRoles[yinjaId].attributes.airStrikeExpired = 0;
        userCoordinates[userRoles[yinjaId].getPositionsKey()] = 0;
        userCoordinates[keccak256(abi.encodePacked(x, y))] = yinjaId;
        userRoles[yinjaId].statistic.moveCount += 1;
        userRoles[yinjaId].positions.x = x;
        userRoles[yinjaId].positions.y = y;
        userRoles[yinjaId].positions.areaNumber = mapVars.getAreaNumber(x, y);

        emit Move(yinjaId, x, y, userRoles[yinjaId].positions.areaNumber);
    }

    function evacuate(uint256 yinjaId)
        external
        isAuthorizedForToken(msg.sender, yinjaId)
        checkRoleStatus(yinjaId)
        returns (uint256 prize)
    {
        require(
            !userRoles[yinjaId].isDismissed() &&
                !userRoles[yinjaId].isClaimed(),
            "YINJA Survivor: evacuate failed"
        );
        if (userRoles[yinjaId].isWinner()) {
            prize = winnerWithdraw(yinjaId);
        } else {
            userRoles[yinjaId].setEvacuated();
            userCoordinates[userRoles[yinjaId].getPositionsKey()] = 0;
            survivorVars.remainSurvivors -= 1;
            prize = userRoles[yinjaId].prize;
            if (survivorVars.isOpenBounsPrize()) {
                survivorVars.prizePool -= survivorVars.getEvacuatePrize();
                prize += survivorVars.getEvacuatePrize();
                userRoles[yinjaId].setClaimed();
                userRoles[yinjaId].prize = 0;
                payable(msg.sender).transfer(prize);
                emit TransferEvacuatePrize(prize, yinjaId, msg.sender);
            }
        }
    }

    function winnerWithdraw(uint256 yinjaId)
        public
        isAuthorizedForToken(msg.sender, yinjaId)
        returns (uint256 prize)
    {
        require(
            userRoles[yinjaId].isWinner(),
            "YINJA Survivor: only winner can withdraw"
        );
        require(
            !userRoles[yinjaId].isClaimed(),
            "YINJA Survivor: only withdraw once"
        );
        require(survivorVars.isEndStatus(), "YINJA Survivor: only end status");
        prize = survivorVars.prizePool + userRoles[yinjaId].prize;
        survivorVars.prizePool = 0;
        userCoordinates[userRoles[yinjaId].getPositionsKey()] = 0;
        userRoles[yinjaId].prize = 0;
        userRoles[yinjaId].setClaimed();
        payable(msg.sender).transfer(prize);

        emit TransferWinnerPrize(prize, yinjaId, msg.sender);
    }

    function readyAirStrike() external onlyRole(YINJA_GAME_MANAGER) {
        require(
            survivorVars.isReadyAirStrike(),
            "YINJA Survivor: not ready to airstrike"
        );
        require(survivorVars.isStartStatus(), "YINJA Survivor: invalid status");
        survivorVars.salt += 1;
        uint64 maxAreaNumber = mapVars.getMaxNumber();
        uint256 lastAirStrikeNumber = survivorVars.getRandomAreaNumber(
            maxAreaNumber
        );
        setAirStrikeNumber(lastAirStrikeNumber);
        emit ReadyAirStrike(lastAirStrikeNumber);
    }

    function airStrike(uint256[] memory tokenIds)
        external
        onlyRole(YINJA_GAME_MANAGER)
    {
        require(
            survivorVars.isAirStrike(),
            "YINJA Survivor: not airstrike time"
        );
        require(survivorVars.isStartStatus(), "YINJA Survivor: invalid status");
        for (uint256 idx = 0; idx < tokenIds.length; idx++) {
            uint256 tokenId = tokenIds[idx];
            uint256 expiredTime = block.timestamp + 30 minutes;
            // avoid duplicate tokenId seted
            if (userRoles[tokenId].attributes.airStrikeExpired >= expiredTime)
                continue;
            if (userRoles[tokenId].isDismissed()) continue;
            if (
                userRoles[tokenId].positions.areaNumber !=
                survivorVars.lastAirStrikeNumber
            ) continue;
            userRoles[tokenId].statistic.airStrkieCount += 1;
            userRoles[tokenId].attributes.airStrikeExpired = expiredTime;
        }
        survivorVars.lastAirStrikeTimestamp = block.timestamp;
        emit AirStrike(survivorVars.lastAirStrikeNumber);
    }

    function getPositions(uint64 x, uint64 y)
        public
        view
        returns (uint256 tokenId)
    {
        // mark that yinja NFT tokenId begin from _nextId = 1;
        bytes32 positionKey = keccak256(abi.encodePacked(x, y));
        return userCoordinates[positionKey];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawFund() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(survivorVars.isEndStatus(), "YINJA Survivor: invalid status");
        uint256 balance = address(this).balance;
        if (balance > survivorVars.prizePool) {
            uint256 remain = balance - survivorVars.prizePool;
            payable(msg.sender).transfer(remain);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../libraries/SurvivorVars.sol";

interface ISurvivor {
    struct JoinVars {
        uint256 yinjaId;
        uint64 x;
        uint64 y;
        uint64 country;
    }

    event GameStatusChange(SurvivorVars.Status s);
    event SurvivorMapChange(address s);
    event LevelUp(uint256 tokenId, uint256 minCost);
    event ConfirmHit(uint256 tokenId0, uint256 tokenId1);
    event Move(uint256 tokenId, uint64 x, uint64 y, uint64 areaNumber);
    event ReadyAirStrike(uint256 number);
    event AirStrike(uint256 number);
    event TransferEvacuatePrize(uint256 prize, uint256 TokendId, address recipient);
    event TransferWinnerPrize(uint256 prize, uint256 TokenId, address recipient);
    event JoinPlayer(uint256 yinjaId, uint64 x, uint64 y, uint64 country);
    event AirJoinPlayer(uint256 yinjaId, uint64 x, uint64 y, uint64 country);
    event KillCharacter(uint256 tokenId0, uint256 tokenId1);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

library SurvivorRole {
    struct Role {
        uint256 prize;
        Position positions;
        Attribute attributes;
        Statistic statistic;
    }

    struct Position {
        uint64 x;
        uint64 y;
        uint64 areaNumber;
    }

    struct Attribute {
        uint64 level;
        uint64 state;
        uint64 healthPoint;
        uint64 country;
        uint256 shieldExpired;
        uint256 airStrikeExpired;
    }

    struct Statistic {
        uint64 levelUpCount;
        uint64 moveCount;
        uint64 attackCount;
        uint64 airStrkieCount;
        uint64 hitedCount;
    }

    function setJoin(Role storage role) internal {
        role.attributes.state = uint64(role.attributes.state | 1);
    }

    function setDead(Role storage role) internal {
        role.attributes.state = uint64(role.attributes.state | (1 << 2));
    }

    function setEvacuated(Role storage role) internal {
        role.attributes.state = uint64(role.attributes.state | (1 << 4));
    }

    function setWinner(Role storage role) internal {
        role.attributes.state = uint64(role.attributes.state | (1 << 8));
    }

    function setClaimed(Role storage role) internal {
        role.attributes.state = uint64(role.attributes.state | (1 << 16));
    }

    function setPositions(
        Role storage role,
        uint64 x,
        uint64 y
    ) internal {
        role.positions.x = x;
        role.positions.y = y;
    }

    function isJoin(Role storage role) internal view returns (bool) {
        return role.attributes.state & 1 != 0;
    }

    function isDead(Role storage role) internal view returns (bool) {
        return role.attributes.state & (1 << 2) != 0;
    }

    function isEvacuated(Role storage role) internal view returns (bool) {
        return role.attributes.state & (1 << 4) != 0;
    }

    function isWinner(Role storage role) internal view returns (bool) {
        return role.attributes.state & (1 << 8) != 0;
    }

    function isClaimed(Role storage role) internal view returns (bool) {
        return role.attributes.state & (1 << 16) != 0;
    }

    function isDismissed(Role storage role) internal view returns (bool) {
        return isDead(role) || isEvacuated(role);
    }

    function getPositionsKey(Role storage role)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(role.positions.x, role.positions.y));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./RandomSeed.sol";

library SurvivorVars {
    using RandomSeed for uint256;

    // time variable
    uint64 internal constant AIR_STRIKE_INTERVAL = 8 hours;

    enum Stage {
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Status {
        PREPARE,
        START,
        END
    }

    struct Vars {
        uint256 salt;
        uint256 prizePool;
        uint256 lastAirStrikeTimestamp;
        uint256 lastAirStrikeNumber;
        uint256 joinedPlayers;
        uint256 airJoinedPlayers;
        uint256 totalSurvivors;
        uint256 remainSurvivors;
        Status status;
    }

    function isPrepareStatus(Vars storage vars) internal view returns (bool) {
        return vars.status == Status.PREPARE;
    }

    function isStartStatus(Vars storage vars) internal view returns (bool) {
        return vars.status == Status.START;
    }

    function isEndStatus(Vars storage vars) internal view returns (bool) {
        return vars.status == Status.END;
    }

    function isOpenBounsPrize(Vars storage vars) internal view returns (bool) {
        return ((100 * vars.remainSurvivors) / vars.totalSurvivors) <= 30;
    }

    function isFinishedGame(Vars storage vars) internal view returns (bool) {
        return vars.remainSurvivors == 1 || vars.status == Status.END;
    }

    function isReadyAirStrike(Vars storage vars) internal view returns (bool) {
        return
            vars.lastAirStrikeTimestamp + AIR_STRIKE_INTERVAL - 30 minutes <
            block.timestamp;
    }

    function isAirStrike(Vars storage vars) internal view returns (bool) {
        return
            vars.lastAirStrikeTimestamp + AIR_STRIKE_INTERVAL < block.timestamp;
    }

    function getEvacuatePrize(Vars storage vars)
        internal
        view
        returns (uint256)
    {
        return ((vars.prizePool / vars.remainSurvivors) * 50) / 100;
    }

    function getRandomAreaNumber(Vars storage vars, uint256 maxNumber)
        internal
        view
        returns (uint256)
    {
        return (vars.salt.seed() % maxNumber) + 1;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SurvivorMap {
    uint64 internal constant MIN_NUMBER = 1;
    uint64 internal constant COORDINATE_X = 0;
    uint64 internal constant COORDINATE_Y = 0;

    struct MapVars {
        uint64 MAP_WIDTH;
        uint64 MAP_HEIGHT;
        uint64 AREA_WIDTH;
        uint64 AREA_HEIGHT;
    }

    function getWidthAreaNumber(MapVars storage vars)
        internal
        view
        returns (uint64 WIDTH_NUMBER)
    {
        uint64 WIDTH = vars.MAP_WIDTH + 1;
        if (WIDTH % vars.AREA_WIDTH != 0) {
            WIDTH_NUMBER = WIDTH / vars.AREA_WIDTH + 1;
        } else {
            WIDTH_NUMBER = WIDTH / vars.AREA_WIDTH;
        }
    }

    function getHeightAreaNumber(MapVars storage vars)
        internal
        view
        returns (uint64 HEIGHT_NUMBER)
    {
        uint64 HEIGHT = vars.MAP_HEIGHT + 1;
        if (HEIGHT % vars.AREA_HEIGHT != 0) {
            HEIGHT_NUMBER = HEIGHT / vars.AREA_HEIGHT + 1;
        } else {
            HEIGHT_NUMBER = HEIGHT / vars.AREA_HEIGHT;
        }
    }

    function getMaxNumber(MapVars storage vars) internal view returns (uint64) {
        return getWidthAreaNumber(vars) * getHeightAreaNumber(vars);
    }

    function getAreaNumber(
        MapVars storage vars,
        uint64 x,
        uint64 y
    ) internal view returns (uint64) {
        uint64 xs = x / vars.AREA_WIDTH + 1;
        uint64 ys = y / vars.AREA_HEIGHT + 1;

        uint64 widthNumber = getWidthAreaNumber(vars);
        return widthNumber * (ys - 1) + xs;
    }

    function getAreaCoordinate(MapVars storage vars, uint64 number)
        internal
        view
        returns (uint64 x, uint64 y)
    {
        uint64 k = getWidthAreaNumber(vars);
        uint64 height = number / k;
        uint64 width = number % k;
        x = (width == 0 ? k - 1 : width - 1) * vars.AREA_WIDTH;
        y = (width != 0 ? height : height - 1) * vars.AREA_HEIGHT;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library RandomSeed {
    function seed(uint256 salt) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            uint256(
                                keccak256(abi.encodePacked(block.coinbase))
                            ) /
                            block.timestamp +
                            block.gaslimit +
                            block.number +
                            salt
                    )
                )
            );
    }
}
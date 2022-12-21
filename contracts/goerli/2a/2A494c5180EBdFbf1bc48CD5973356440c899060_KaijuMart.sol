// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IKaijuMart.sol";

error KaijuMart_CannotClaimRefund();
error KaijuMart_CannotRedeemAuction();
error KaijuMart_InvalidRedeemerContract();
error KaijuMart_InvalidTokenType();
error KaijuMart_LotAlreadyExists();
error KaijuMart_LotDoesNotExist();
error KaijuMart_MustBeAKing();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title KaijuMart
 * @author Augminted Labs, LLC
 */
contract KaijuMart is IKaijuMart, AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    KaijuContracts public kaijuContracts;
    ManagerContracts public managerContracts;
    mapping(uint256 => Lot) public lots;

    constructor(
        KaijuContracts memory _kaijuContracts,
        ManagerContracts memory _managerContracts,
        address admin
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        kaijuContracts = _kaijuContracts;
        managerContracts = _managerContracts;
    }

    /**
     * @notice Modifier that requires a sender to be part of the KaijuKingz ecosystem
     */
    modifier onlyKingz() {
        if (!isKing(_msgSender())) revert KaijuMart_MustBeAKing();
        _;
    }

    /**
     * @notice Modifier that ensures a lot identifier is unused
     * @param lotId Globally unique identifier for a lot
     */
    modifier reserveLot(uint256 lotId) {
        if (lots[lotId].lotType != LotType.NONE) revert KaijuMart_LotAlreadyExists();
        _;
    }

    /**
     * @notice Modifier that ensures a lot exists
     * @param lotId Unique identifier for a lot
     */
    modifier lotExists(uint256 lotId) {
        if (lots[lotId].lotType == LotType.NONE) revert KaijuMart_LotDoesNotExist();
        _;
    }

    /**
     * @notice Returns whether or not an address holds any KaijuKingz ecosystem tokens
     * @param account Address to return the holder status of
     */
    function isKing(address account) public view returns (bool) {
        return kaijuContracts.scientists.balanceOf(account) > 0
            || kaijuContracts.mutants.balanceOf(account) > 0
            || kaijuContracts.kaiju.isHolder(account);
    }

    /**
     * @notice Set KaijuKingz contracts
     * @param _kaijuContracts New set of KaijuKingz contracts
     */
    function setKaijuContracts(KaijuContracts calldata _kaijuContracts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        kaijuContracts = _kaijuContracts;
    }

    /**
     * @notice Set manager contracts
     * @param _managerContracts New set of manager contract
     */
    function setManagerContracts(ManagerContracts calldata _managerContracts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        managerContracts = _managerContracts;
    }

    /**
     * @notice Return the address of the manager contract for a specified lot type
     * @param lotType Specified lot type
     */
    function _manager(LotType lotType) internal view returns (address) {
        if (lotType == LotType.RAFFLE) return address(managerContracts.raffle);
        else if (lotType == LotType.DOORBUSTER) return address(managerContracts.doorbuster);
        else if (lotType == LotType.AUCTION) return address(managerContracts.auction);
        else return address(0);
    }

    /**
     * @notice Create a new lot
     * @param id Unique identifier
     * @param lot Struct describing lot
     * @param lotType Sale mechanism of the lot
     * @param rwastePrice Price in $RWASTE when applicable
     * @param scalesPrice Price in $SCALES when applicable
     */
    function _create(
        uint256 id,
        CreateLot calldata lot,
        LotType lotType,
        uint104 rwastePrice,
        uint104 scalesPrice
    )
        internal
    {
        if (
            address(lot.redeemer) != address(0) &&
            !lot.redeemer.supportsInterface(type(IKaijuMartRedeemable).interfaceId)
        ) revert KaijuMart_InvalidRedeemerContract();

        lots[id] = Lot({
            rwastePrice: rwastePrice,
            scalesPrice: scalesPrice,
            lotType: lotType,
            paymentToken: lot.paymentToken,
            redeemer: lot.redeemer
        });

        emit Create(id, lotType, _manager(lotType));
    }

    /**
     * @notice Calculate the cost of a lot based on amount
     * @param lotId Lot to calculate cost for
     * @param amount Number of items to purchase
     * @param token Preferred payment token type
     */
    function _getCost(
        uint256 lotId,
        uint32 amount,
        PaymentToken token
    )
        internal
        view
        returns (uint104)
    {
        PaymentToken acceptedPaymentToken = lots[lotId].paymentToken;

        if (acceptedPaymentToken != PaymentToken.EITHER && acceptedPaymentToken != token)
            revert KaijuMart_InvalidTokenType();

        return amount * (token == PaymentToken.SCALES ? lots[lotId].scalesPrice : lots[lotId].rwastePrice);
    }

    /**
     * @notice Charge an account a specified amount of tokens
     * @dev Payment defaults to $RWASTE if `EITHER` is specified
     * @param account Address to charge
     * @param token Preferred payment token
     * @param value Amount to charge
     */
    function _charge(
        address account,
        PaymentToken token,
        uint104 value
    )
        internal
        nonReentrant
    {
        if (value > 0) {
            if (token == PaymentToken.SCALES) kaijuContracts.scales.spend(account, value);
            else kaijuContracts.rwaste.burn(account, value);
        }
    }

    /**
     * @notice Refund an account a specified amount of tokens
     * @dev No payment default, if `EITHER` is specified this is a noop
     * @param account Address to refund
     * @param token Type of tokens to refund
     * @param value Amount of tokens to refund
     */
    function _refund(
        address account,
        PaymentToken token,
        uint104 value
    )
        internal
        nonReentrant
    {
        if (token == PaymentToken.RWASTE) kaijuContracts.rwaste.claimLaboratoryExperimentRewards(account, value);
        else if (token == PaymentToken.SCALES) kaijuContracts.scales.credit(account, value);
    }

    /**
     * @notice Redeem a lot
     * @param lotId Lot to redeem
     * @param amount Quantity to redeem
     * @param to Address redeeming the lot
     */
    function _redeem(
        uint256 lotId,
        uint32 amount,
        address to
    )
        internal
        nonReentrant
    {
        IKaijuMartRedeemable redeemer = lots[lotId].redeemer;

        if (address(redeemer) != address(0)) {
            redeemer.kmartRedeem(lotId, amount, to);

            emit Redeem(lotId, amount, to, redeemer);
        }
    }

    // 📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣
    // 📣                                          AUCTION MANAGER                                           📣
    // 📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣📣

    /**
     * @notice Return the details of an auction
     * @param auctionId Lot identifier for the auction
     */
    function getAuction(
        uint256 auctionId
    )
        public
        view
        returns (IAuctionManager.Auction memory)
    {
        return managerContracts.auction.get(auctionId);
    }

    /**
     * @notice Return an account's current bid on an auction lot
     * @param auctionId Lot identifier for the auction
     * @param account Address to return the current bid of
     */
    function getBid(
        uint256 auctionId,
        address account
    )
        public
        view
        returns (uint104)
    {
        return managerContracts.auction.getBid(auctionId, account);
    }

    /**
     * @notice Create a new auction lot
     * @param lotId Globally unique lot identifier
     * @param auction Configuration details of the new auction lot
     */
    function createAuction(
        uint256 lotId,
        CreateLot calldata lot,
        IAuctionManager.CreateAuction calldata auction
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        if (lot.paymentToken == PaymentToken.EITHER) revert KaijuMart_InvalidTokenType();

        _create(lotId, lot, LotType.AUCTION, 0, 0);
        managerContracts.auction.create(lotId, auction);
    }

    /**
     * @notice Close an auction lot
     * @param auctionId Lot identifier for the auction
     * @param lowestWinningBid Lowest amount that is considered a winning bid
     * @param tiebrokenWinners An array of winning addresses use to tiebreak identical winning bids
     */
    function close(
        uint256 auctionId,
        uint104 lowestWinningBid,
        address[] calldata tiebrokenWinners
    )
        external
        lotExists(auctionId)
        onlyRole(MANAGER_ROLE)
    {
        managerContracts.auction.close(auctionId, lowestWinningBid, tiebrokenWinners);
    }

    /**
     * @notice Replaces the sender's current bid on an auction lot
     * @dev Auctions cannot accept `EITHER` PaymentType so we can just assume the token type from the auction details
     * @param auctionId Lot identifier for the auction
     * @param value New bid to replace the current bid with
     */
    function bid(
        uint256 auctionId,
        uint104 value
    )
        external
        lotExists(auctionId)
        onlyKingz
    {
        uint104 increase = managerContracts.auction.bid(auctionId, value, _msgSender());

        _charge(
            _msgSender(),
            lots[auctionId].paymentToken,
            increase
        );

        emit Bid(auctionId, _msgSender(), value);
    }

    /**
     * @notice Claim a refund for spent tokens on a lost auction lot
     * @param auctionId Lot identifier for the auction
     */
    function refund(
        uint256 auctionId
    )
        external
        lotExists(auctionId)
    {
        if (managerContracts.auction.isWinner(auctionId, _msgSender())) revert KaijuMart_CannotClaimRefund();

        uint104 refundAmount = managerContracts.auction.settle(auctionId, _msgSender());

        _refund(
            _msgSender(),
            lots[auctionId].paymentToken,
            refundAmount
        );

        emit Refund(auctionId, _msgSender(), refundAmount);
    }

    /**
     * @notice Redeem a winning auction lot
     * @param auctionId Lot identifier for the auction
     */
    function redeem(
        uint256 auctionId
    )
        external
        lotExists(auctionId)
    {
        if (!managerContracts.auction.isWinner(auctionId, _msgSender())) revert KaijuMart_CannotRedeemAuction();

        managerContracts.auction.settle(auctionId, _msgSender());

        _redeem(auctionId, 1, _msgSender());
    }

    // 🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟
    // 🎟                                           RAFFLE MANAGER                                           🎟
    // 🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟🎟

    /**
     * @notice Return the details of a raffle
     * @param raffleId Lot identifier for the raffle
     */
    function getRaffle(
        uint256 raffleId
    )
        public
        view
        returns (IRaffleManager.Raffle memory)
    {
        return managerContracts.raffle.get(raffleId);
    }

    /**
     * @notice Create a new raffle lot
     * @param lotId Globally unique lot identifier
     * @param raffle Configuration details of the new raffle lot
     */
    function createRaffle(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        IRaffleManager.CreateRaffle calldata raffle
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        _create(lotId, lot, LotType.RAFFLE, rwastePrice, scalesPrice);
        managerContracts.raffle.create(lotId, raffle);
    }

    /**
     * @notice Draw the results of a raffle lot
     * @param raffleId Lot identifier for the raffle
     * @param vrf Flag indicating if the results should be drawn using Chainlink VRF
     */
    function draw(
        uint256 raffleId,
        bool vrf
    )
        external
        lotExists(raffleId)
        onlyRole(MANAGER_ROLE)
    {
        managerContracts.raffle.draw(raffleId, vrf);
    }

    /**
     * @notice Purchase entry into a raffle lot
     * @param raffleId Lot identifier for the raffle
     * @param amount Number of entries to purchase
     * @param token Preferred payment token
     */
    function enter(
        uint256 raffleId,
        uint32 amount,
        PaymentToken token
    )
        external
        lotExists(raffleId)
        onlyKingz
    {
        managerContracts.raffle.enter(raffleId, amount);

        _charge(
            _msgSender(),
            token,
            _getCost(raffleId, amount, token)
        );

        emit Enter(raffleId, _msgSender(), amount);
    }

    // 🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒
    // 🛒                                         DOORBUSTER MANAGER                                         🛒
    // 🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒🛒

    /**
     * @notice Return the details of a doorbuster
     * @param doorbusterId Lot identifier for the doorbuster
     */
    function getDoorbuster(
        uint256 doorbusterId
    )
        public
        view
        returns (IDoorbusterManager.Doorbuster memory)
    {
        return managerContracts.doorbuster.get(doorbusterId);
    }

    /**
     * @notice Create a new doorbuster lot
     * @param lotId Globally unique lot identifier
     * @param supply Total purchasable supply
     */
    function createDoorbuster(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        uint32 supply
    )
        external
        reserveLot(lotId)
        onlyRole(MANAGER_ROLE)
    {
        _create(lotId, lot, LotType.DOORBUSTER, rwastePrice, scalesPrice);
        managerContracts.doorbuster.create(lotId, supply);
    }

    /**
     * @notice Purchase from a doorbuster lot
     * @param doorbusterId Lot identifier for the doorbuster
     * @param amount Number of items to purchase
     * @param token Preferred payment token
     * @param nonce Single use number encoded into signature
     * @param signature Signature created by the current doorbuster `signer` account
     */
    function purchase(
        uint256 doorbusterId,
        uint32 amount,
        PaymentToken token,
        uint256 nonce,
        bytes calldata signature
    )
        external
        lotExists(doorbusterId)
        onlyKingz
    {
        managerContracts.doorbuster.purchase(doorbusterId, amount, nonce, signature);

        _charge(
            _msgSender(),
            token,
            _getCost(doorbusterId, amount, token)
        );

        _redeem(doorbusterId, amount, _msgSender());

        emit Purchase(doorbusterId, _msgSender(), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IKingzInTheShell.sol";
import "./IMutants.sol";
import "./IScientists.sol";
import "./IScales.sol";
import "./IRWaste.sol";
import "./IKaijuMartRedeemable.sol";
import "./IAuctionManager.sol";
import "./IDoorbusterManager.sol";
import "./IRaffleManager.sol";
import "./IKaijuMart.sol";

interface IKaijuMart {
    enum LotType {
        NONE,
        AUCTION,
        RAFFLE,
        DOORBUSTER
    }

    enum PaymentToken {
        RWASTE,
        SCALES,
        EITHER
    }

    struct Lot {
        uint104 rwastePrice;
        uint104 scalesPrice;
        LotType lotType;
        PaymentToken paymentToken;
        IKaijuMartRedeemable redeemer;
    }

    struct CreateLot {
        PaymentToken paymentToken;
        IKaijuMartRedeemable redeemer;
    }

    struct KaijuContracts {
        IKingzInTheShell kaiju;
        IMutants mutants;
        IScientists scientists;
        IRWaste rwaste;
        IScales scales;
    }

    struct ManagerContracts {
        IAuctionManager auction;
        IDoorbusterManager doorbuster;
        IRaffleManager raffle;
    }

    event Create(
        uint256 indexed id,
        LotType indexed lotType,
        address indexed managerContract
    );

    event Bid(
        uint256 indexed id,
        address indexed account,
        uint104 value
    );

    event Redeem(
        uint256 indexed id,
        uint32 indexed amount,
        address indexed to,
        IKaijuMartRedeemable redeemer
    );

    event Refund(
        uint256 indexed id,
        address indexed account,
        uint104 value
    );

    event Purchase(
        uint256 indexed id,
        address indexed account,
        uint64 amount
    );

    event Enter(
        uint256 indexed id,
        address indexed account,
        uint64 amount
    );

    // 🦖👑👶🧬👨‍🔬👩‍🔬🧪

    function isKing(address account) external view returns (bool);

    // 💻💻💻💻💻 ADMIN FUNCTIONS 💻💻💻💻💻

    function setKaijuContracts(KaijuContracts calldata _kaijuContracts) external;

    function setManagerContracts(ManagerContracts calldata _managerContracts) external;

    // 📣📣📣📣📣 AUCTION FUNCTIONS 📣📣📣📣📣

    function getAuction(uint256 auctionId) external view returns (IAuctionManager.Auction memory);

    function getBid(uint256 auctionId, address account) external view returns (uint104);

    function createAuction(
        uint256 lotId,
        CreateLot calldata lot,
        IAuctionManager.CreateAuction calldata auction
    ) external;

    function close(
        uint256 auctionId,
        uint104 lowestWinningBid,
        address[] calldata tiebrokenWinners
    ) external;

    function bid(uint256 auctionId, uint104 value) external;

    function refund(uint256 auctionId) external;

    function redeem(uint256 auctionId) external;

    // 🎟🎟🎟🎟🎟 RAFFLE FUNCTIONS 🎟🎟🎟🎟🎟

    function getRaffle(uint256 raffleId) external view returns (IRaffleManager.Raffle memory);

    function createRaffle(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        IRaffleManager.CreateRaffle calldata raffle
    ) external;

    function draw(uint256 raffleId, bool vrf) external;

    function enter(uint256 raffleId, uint32 amount, PaymentToken token) external;

    // 🛒🛒🛒🛒🛒 DOORBUSTER FUNCTIONS 🛒🛒🛒🛒🛒

    function getDoorbuster(uint256 doorbusterId) external view returns (IDoorbusterManager.Doorbuster memory);

    function createDoorbuster(
        uint256 lotId,
        CreateLot calldata lot,
        uint104 rwastePrice,
        uint104 scalesPrice,
        uint32 supply
    ) external;

    function purchase(
        uint256 doorbusterId,
        uint32 amount,
        PaymentToken token,
        uint256 nonce,
        bytes calldata signature
    ) external;
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKingzInTheShell is IERC721 {
    function isHolder(address) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMutants is IERC721 {}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IScientists is IERC721 {}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IScales is IERC20 {
    function spend(address, uint256) external;
    function credit(address, uint256) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRWaste is IERC20 {
    function burn(address, uint256) external;
    function claimLaboratoryExperimentRewards(address, uint256) external;
}

// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

pragma solidity ^0.8.0;

interface IKaijuMartRedeemable is IERC165 {
    function kmartRedeem(uint256 lotId, uint32 amount, address to) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IAuctionManager {
    struct CreateAuction {
        uint104 reservePrice;
        uint16 winners;
        uint64 endsAt;
    }

    struct Auction {
        uint104 reservePrice;
        uint104 lowestWinningBid;
        uint16 winners;
        uint64 endsAt;
    }

    function get(uint256 id) external view returns (Auction memory);
    function getBid(uint256 id, address sender) external view returns (uint104);
    function isWinner(uint256 id, address sender) external view returns (bool);
    function create(uint256 id, CreateAuction calldata auction) external;
    function close(uint256 id, uint104 lowestWinningBid, address[] calldata _tiebrokenWinners) external;
    function bid(uint256 id, uint104 value, address sender) external returns (uint104);
    function settle(uint256 id, address sender) external returns (uint104);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IDoorbusterManager {
    struct Doorbuster {
        uint32 supply;
    }

    function get(uint256 id) external view returns (Doorbuster memory);
    function create(uint256 id, uint32 supply) external;
    function purchase(
        uint256 id,
        uint32 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IRaffleManager {
    struct CreateRaffle {
        uint64 scriptId;
        uint64 winners;
        uint64 endsAt;
    }

    struct Raffle {
        uint256 seed;
        uint64 scriptId;
        uint64 winners;
        uint64 endsAt;
    }

    function get(uint256 id) external view returns (Raffle memory);
    function isDrawn(uint256 id) external view returns (bool);
    function create(uint256 id, CreateRaffle calldata raffle) external;
    function enter(uint256 id, uint32 amount) external;
    function draw(uint256 id, bool vrf) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
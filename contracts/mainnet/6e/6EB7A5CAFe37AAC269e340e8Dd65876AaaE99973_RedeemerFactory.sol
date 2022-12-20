// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Redeemer.sol";
import "./interfaces/IRedeemerFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RedeemerFactory is IRedeemerFactory, Ownable {
    int public constant Version = 3;

    address public protocolManagerAddr;

    function setPMAddress(address _pmAddress) external onlyOwner {
        require(_pmAddress != address(0x0), "ZERO Addr is not allowed");
        protocolManagerAddr = _pmAddress;
    }

    function createRedeemerContract(
        address fluentToken,
        address burnerContract,
        address fedMember,
        address redeemersBookkeper,
        address redeemersTreasury
    ) external returns (address) {
        require(msg.sender == protocolManagerAddr, "Caller is not the PM");
        Redeemer newRedeemer = new Redeemer(
            fluentToken,
            burnerContract,
            fedMember,
            redeemersBookkeper,
            redeemersTreasury
        );

        return address(newRedeemer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IRedeemer.sol";
import "./interfaces/IUSPlusBurner.sol";
import "./interfaces/IFluentUSPlus.sol";
import "./interfaces/IRedeemersBookkeeper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Federation member´s Contract for redeem balance
/// @author Fluent Group - Development team
/// @notice Use this contract for request US dollars back
/// @dev
contract Redeemer is IRedeemer, Pausable, AccessControl {
    int public constant Version = 3;
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE =
        keccak256("TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE");

    address public fedMemberId;
    address public USPlusBurnerAddr;
    address public fluentUSPlusAddress;
    address public redeemersBookkeeper;
    address public redeemerTreasury;

    constructor(
        address _fluentUSPlusAddress,
        address _USPlusBurnerAddr,
        address _fedMemberId,
        address _redeemerBookkeeper,
        address _redeemerTreasury
    ) {
        require(
            _fluentUSPlusAddress != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_USPlusBurnerAddr != address(0x0), "ZERO Addr is not allowed");
        require(_fedMemberId != address(0x0), "ZERO Addr is not allowed");
        require(
            _redeemerBookkeeper != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_redeemerTreasury != address(0x0), "ZERO Addr is not allowed");

        _grantRole(DEFAULT_ADMIN_ROLE, _fedMemberId);
        _grantRole(PAUSER_ROLE, _fedMemberId);
        _grantRole(APPROVER_ROLE, _fedMemberId);

        fluentUSPlusAddress = _fluentUSPlusAddress;
        USPlusBurnerAddr = _USPlusBurnerAddr;
        fedMemberId = _fedMemberId;
        redeemersBookkeeper = _redeemerBookkeeper;
        redeemerTreasury = _redeemerTreasury;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Entry point to a user request redeem their US+ back to FIAT
    /// @dev
    /// @param amount The requested amount
    /// @param refId The Ticket Id generated in Core Banking System
    function requestRedeem(
        uint256 amount,
        bytes32 refId
    ) external whenNotPaused returns (bool isRequestPlaced) {
        require(
            verifyRole(USER_ROLE, msg.sender),
            "Caller does not have the role to request redeem"
        );
        require(
            IERC20(fluentUSPlusAddress).balanceOf(msg.sender) >= amount,
            "NOT_ENOUGH_BALANCE"
        );
        require(
            IERC20(fluentUSPlusAddress).allowance(msg.sender, address(this)) >=
                amount,
            "NOT_ENOUGH_ALLOWANCE"
        );

        require(!getUsedTicketsInfo(refId), "ALREADY_USED_REFID"); //needs to send to redeemers bookkeeping

        emit RedeemRequested(msg.sender, amount, refId);

        BurnTicket memory ticket = IRedeemer.BurnTicket({
            refId: refId,
            from: msg.sender,
            amount: amount,
            placedBlock: block.number,
            confirmedBlock: 0,
            usedTicket: true,
            ticketStatus: TicketStatus.PENDING
        });

        _setBurnTickets(refId, ticket);
        require(
            IERC20(fluentUSPlusAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "FAIL_TRANSFER"
        );

        return true;
    }

    /// @notice Set a Ticket to approved or not approved
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    /// @param isApproved boolean condition for this Ticket
    function approveTickets(
        bytes32 refId,
        bool isApproved
    ) external onlyRole(APPROVER_ROLE) {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);
        require(ticket.usedTicket, "INVALID_TICKED_ID");
        require(
            ticket.ticketStatus == TicketStatus.PENDING,
            "INVALID_TICKED_STATUS"
        );

        if (isApproved) {
            _approvedTicket(refId);
        } else {
            _setRejectedAmounts(refId, true);

            BurnTicket memory _ticket = IRedeemer.BurnTicket({
                refId: ticket.refId,
                from: ticket.from,
                amount: ticket.amount,
                placedBlock: ticket.placedBlock,
                confirmedBlock: ticket.confirmedBlock,
                usedTicket: ticket.usedTicket,
                ticketStatus: TicketStatus.REJECTED
            });

            _setBurnTickets(refId, _ticket);
        }
    }

    /// @notice Set a Ticket to approved and send it to US+
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function _approvedTicket(
        bytes32 refId
    )
        internal
        onlyRole(APPROVER_ROLE)
        whenNotPaused
        returns (bool isTicketApproved)
    {
        emit RedeemApproved(refId);

        BurnTicket memory ticket = _getBurnTicketInfo(refId); //retrieve from the bookkeeper

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.APPROVED
        });

        _setBurnTickets(refId, _ticket);
        require(
            IUSPlusBurner(USPlusBurnerAddr).requestBurnUSPlus(
                ticket.refId,
                address(this),
                ticket.from,
                fedMemberId,
                ticket.amount
            )
        );

        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                USPlusBurnerAddr,
                ticket.amount
            ),
            "INCREASE_ALLOWANCE_FAIL"
        );

        return true;
    }

    /// @notice Allows the FedMember give a destination for a seized value
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    /// @param recipient The target address where the values will be addressed
    function transferRejectedAmounts(
        bytes32 refId,
        address recipient
    ) external onlyRole(TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE) whenNotPaused {
        require(
            !hasRole(APPROVER_ROLE, msg.sender),
            "Call not allowed. Caller has also Approver Role"
        );

        require(_getRejectedAmounts(refId), "Not a rejected refId");

        BurnTicket memory ticket = _getBurnTicketInfo(refId); //retrieve from the keeper
        require(
            ticket.ticketStatus == TicketStatus.REJECTED,
            "Ticket not rejected"
        );

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.TRANSFERED
        });

        emit RejectedAmountsTransfered(refId, recipient);

        _setBurnTickets(refId, _ticket);

        _setRejectedAmounts(refId, false); //send to the keeper
        require(
            IERC20(fluentUSPlusAddress).transfer(recipient, ticket.amount),
            "FAIL_TRANSFER"
        );
    }

    function revertTicketRejection(
        bytes32 refId
    ) external onlyRole(APPROVER_ROLE) whenNotPaused {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);
        require(
            ticket.ticketStatus == TicketStatus.REJECTED,
            "Ticket not rejected"
        );

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.PENDING
        });

        _setBurnTickets(refId, _ticket);

        _setRejectedAmounts(refId, false);
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function getBurnReceiptById(
        bytes32 refId
    ) external view returns (BurnTicket memory) {
        // return burnTickets[refId];
        return _getBurnTicketInfo(refId); //retrieve from the bookkeper
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    function getBurnStatusById(
        bytes32 refId
    ) external view returns (bool, TicketStatus, uint256) {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);

        if (ticket.usedTicket) {
            return (
                ticket.usedTicket,
                ticket.ticketStatus,
                ticket.confirmedBlock //retrieve from the bookkeper
            );
        } else {
            return (false, TicketStatus.NOT_EXIST, 0);
        }
    }

    function rejectedAmount(bytes32 refId) external view returns (bool) {
        return _getRejectedAmounts(refId);
    }

    function setErc20AllowList(
        address erc20Addr,
        bool status
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE) {
        require(
            !_getErc20AllowList(erc20Addr),
            "Address already in the ERC20 AllowList"
        );
        _setErc20AllowList(erc20Addr, status);
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        require(
            _getErc20AllowList(erc20Addr),
            "Address not in the ERC20 AllowList"
        );
        require(IERC20(erc20Addr).transfer(to, amount), "Fail");
    }

    //Access control stored in the redeemersKeeper
    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
        IRedeemersBookkeeper(redeemersBookkeeper).setRoleControl(
            role,
            account,
            fedMemberId
        );
    }

    function verifyRole(
        bytes32 role,
        address account
    ) public view returns (bool _hasRole) {
        _hasRole = IRedeemersBookkeeper(redeemersBookkeeper).getRoleControl(
            role,
            account,
            fedMemberId
        );
        return _hasRole;
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
        IRedeemersBookkeeper(redeemersBookkeeper).revokeRoleControl(
            role,
            account,
            fedMemberId
        );
    }

    function getUsedTicketsInfo(bytes32 refId) public view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper)
                .getBurnTickets(fedMemberId, refId)
                .usedTicket;
    }

    function _getBurnTicketInfo(
        bytes32 refId
    ) internal view returns (IRedeemer.BurnTicket memory _burnTickets) {
        _burnTickets = IRedeemersBookkeeper(redeemersBookkeeper).getBurnTickets(
            fedMemberId,
            refId
        );
        return _burnTickets;
    }

    function _setBurnTickets(bytes32 refId, BurnTicket memory ticket) internal {
        IRedeemersBookkeeper(redeemersBookkeeper).setTickets(
            fedMemberId,
            refId,
            ticket
        );
    }

    function _setRejectedAmounts(bytes32 refId, bool status) internal {
        emit RedeemRejected(refId);

        IRedeemersBookkeeper(redeemersBookkeeper).setRejectedAmounts(
            refId,
            fedMemberId,
            status
        );
    }

    function _getRejectedAmounts(bytes32 refId) internal view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getRejectedAmounts(
                refId,
                fedMemberId
            );
    }

    function _setErc20AllowList(address tokenAddress, bool status) internal {
        IRedeemersBookkeeper(redeemersBookkeeper).setErc20AllowListToken(
            fedMemberId,
            tokenAddress,
            status
        );
    }

    function _getErc20AllowList(
        address tokenAddress
    ) internal view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getErc20AllowListToken(
                fedMemberId,
                tokenAddress
            );
    }

    function getErc20AllowList(
        address tokenAddress
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getErc20AllowListToken(
                fedMemberId,
                tokenAddress
            );
    }

    function prepareMigration() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint currentBalance = IERC20(fluentUSPlusAddress).balanceOf(
            address(this)
        );
        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                redeemerTreasury,
                currentBalance
            ),
            "Fail to increase allowance"
        );
    }

    function increaseAllowanceToBurner(
        uint amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                USPlusBurnerAddr,
                amount
            ),
            "INCREASE_ALLOWANCE_FAIL"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedeemerFactory {
    function createRedeemerContract(
        address fluentToken,
        address burnerContract,
        address fedMember,
        address redeemersBookkeper,
        address redeemersTreasury
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedeemer {
    event RedeemRequested(address indexed user, uint256 amount, bytes32 refId);
    event RedeemApproved(bytes32 refId);
    event RedeemRejected(bytes32 refId);
    event RejectedAmountsTransfered(bytes32 refId, address indexed recipient);

    enum TicketStatus {
        NOT_EXIST,
        PENDING,
        APPROVED,
        TRANSFERED,
        REJECTED
    }

    struct BurnTicket {
        bytes32 refId;
        address from;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool usedTicket;
        TicketStatus ticketStatus;
    }

    function requestRedeem(
        uint256 amount,
        bytes32 refId
    ) external returns (bool isRequestPlaced);

    function approveTickets(bytes32 refId, bool isApproved) external;

    function transferRejectedAmounts(bytes32 refId, address recipient) external;

    function revertTicketRejection(bytes32 refId) external;

    function getBurnReceiptById(
        bytes32 refId
    ) external view returns (BurnTicket memory);

    function getBurnStatusById(
        bytes32 refId
    ) external view returns (bool, TicketStatus, uint256);

    function setErc20AllowList(address erc20Addr, bool status) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;

    function increaseAllowanceToBurner(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUSPlusBurner {
    struct BurnTicket {
        bytes32 refId;
        address redeemerContractAddress;
        address redeemerPerson;
        address fedMemberID;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool executed;
    }

    ///@dev arrays of refIds
    struct BurnTicketId {
        bytes32 refId;
        address fedMemberId;
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnReceiptById(
        bytes32 id
    ) external view returns (BurnTicket memory);

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnStatusById(
        bytes32 id
    ) external view returns (bool, bool, uint256);

    function toGrantRole(address _to) external;

    /// @notice Execute transferFrom Executer Acc to this contract, and open a burn Ticket
    /// @dev to match the id the fields should be (burnCounter, _refNo, amount, msg.sender)
    /// @param refId Ref Code provided by customer to identify this request
    /// @param redeemerContractAddress The Federation Member´s REDEEMER contract
    /// @param redeemerPerson The person who is requesting USD Redeem
    /// @param fedMemberID Identification for Federation Member
    /// @param amount The amount to be burned
    /// @return isRequestPlaced confirmation if Function gets to the end without revert
    function requestBurnUSPlus(
        bytes32 refId,
        address redeemerContractAddress,
        address redeemerPerson,
        address fedMemberID,
        uint256 amount
    ) external returns (bool isRequestPlaced);

    /// @notice Burn the amount of US defined in the ticket
    /// @dev Be aware that burnID is formed by a hash of (mapping.burnCounter, mapping._refNo, amount, _redeemBy), see requestBurnUSPlus method
    /// @param refId Burn TicketID
    /// @param redeemerContractAddress address from the amount get out
    /// @param fedMemberId Federation Member ID
    /// @param amount Burn amount requested
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(
        bytes32 refId,
        address redeemerContractAddress,
        address fedMemberId,
        uint256 amount,
        address vault
    ) external returns (bool isAmountBurned);

    function setComplianceManagerAddr(
        address newComplianceManagerAddr
    ) external;

    function setUSPlusAddr(address newUSPlusAddr) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFluentUSPlus {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint amount) external;

    function mint(address to, uint amount) external returns (bool);

    function increaseAllowance(
        address spender,
        uint addedValue
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IRedeemer.sol";

interface IRedeemersBookkeeper {
    function setTickets(
        address fedMember,
        bytes32 refId,
        IRedeemer.BurnTicket memory ticket
    ) external;

    function setRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external;

    function getRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external view returns (bool _hasRole);

    function revokeRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external;

    function getBurnTickets(
        address fedMember,
        bytes32 refId
    ) external view returns (IRedeemer.BurnTicket memory _burnTickets);

    function setRejectedAmounts(
        bytes32 refId,
        address fedMember,
        bool status
    ) external;

    function getRejectedAmounts(
        bytes32 refId,
        address fedMember
    ) external view returns (bool);

    function setErc20AllowListToken(
        address fedMember,
        address tokenAddress,
        bool status
    ) external;

    function getErc20AllowListToken(
        address fedMember,
        address tokenAddress
    ) external view returns (bool);

    function setRedeemerStatus(address redeemer, bool status) external;

    function getRedeemerStatus(address redeemer) external view returns (bool);

    function toGrantRole(address redeemerContract) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
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
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
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
        _paused = false;
        emit Unpaused(_msgSender());
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
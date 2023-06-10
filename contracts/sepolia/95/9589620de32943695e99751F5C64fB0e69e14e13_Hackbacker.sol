pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Hackbacker is Ownable {
    enum EscrowMemberState {
        CREATED,
        DEPOSITED,
        WITHDRAWN,
        CONTESTED
    }

    enum EscrowState {
        CREATED,
        ONGOING,
        CANCELLED,
        WITHDRAWN,
        CONTESTED,
        RESOLVED
    }

    enum User {
        HOST,
        GUEST
    }

    struct Escrow {
        address host;
        address guest;
        uint256 hostDeposit;
        uint256 guestDeposit;
        EscrowMemberState hostState;
        EscrowMemberState guestState;
        EscrowState state;
        uint256 endTimestamp;
    }

    Escrow[] public escrows;

    IERC20 public immutable escrowToken;

    event EscrowCreated(
        uint256 escrowId,
        address host,
        uint256 hostDeposit,
        uint256 guestDeposit,
        uint256 endTimestamp
    );
    event EscrowDeposited(uint256 escrowId, address depositor, User userType);
    event EscrowWithdrawn(uint256 escrowId, uint256 amount, User userType);
    event EscrowContested(uint256 escrowId, User userType);
    event EscrowResolved(
        uint256 escrowId,
        uint256 hostPercentage,
        uint256 guestPercentage
    );

    constructor(address _escrowToken) {
        escrowToken = IERC20(_escrowToken);
    }

    function createEscrow(
        uint256 _hostDeposit,
        uint256 _guestDeposit,
        uint256 _endTimestamp
    ) external returns (uint256) {
        require(_hostDeposit > 0, "Host deposit must be greater than 0");
        require(_guestDeposit > 0, "Guest deposit must be greater than 0");
        require(
            _endTimestamp > block.timestamp,
            "End timestamp must be in the future"
        );

        escrows.push(
            Escrow({
                host: msg.sender,
                guest: address(0),
                hostDeposit: _hostDeposit,
                guestDeposit: _guestDeposit,
                hostState: EscrowMemberState.CREATED,
                guestState: EscrowMemberState.CREATED,
                state: EscrowState.CREATED,
                endTimestamp: _endTimestamp
            })
        );

        emit EscrowCreated(
            escrows.length - 1,
            msg.sender,
            _hostDeposit,
            _guestDeposit,
            _endTimestamp
        );

        return escrows.length - 1;
    }

    function deposit(uint256 _escrowId, User _user) external {
        Escrow storage escrow = escrows[_escrowId];

        require(escrow.endTimestamp >= block.timestamp, "Escrow has ended");

        if (_user == User.HOST) {
            require(
                escrow.hostState == EscrowMemberState.CREATED,
                "Host has already deposited"
            );

            escrow.hostState = EscrowMemberState.DEPOSITED;
            escrowToken.transferFrom(
                msg.sender,
                address(this),
                escrow.hostDeposit
            );
        } else {
            require(
                escrow.guestState == EscrowMemberState.CREATED,
                "Escrow already has a guest"
            );

            escrow.guest = msg.sender;
            escrow.guestState = EscrowMemberState.DEPOSITED;

            escrowToken.transferFrom(
                msg.sender,
                address(this),
                escrow.guestDeposit
            );
        }

        if (
            escrow.hostState == EscrowMemberState.DEPOSITED &&
            escrow.guestState == EscrowMemberState.DEPOSITED
        ) {
            escrow.state = EscrowState.ONGOING;
        }

        emit EscrowDeposited(_escrowId, msg.sender, _user);
    }

    function withdraw(uint256 _escrowId, User _user) external {
        Escrow storage escrow = escrows[_escrowId];

        require(escrow.state != EscrowState.CONTESTED, "Escrow is contested");
        require(escrow.state != EscrowState.CANCELLED, "Escrow is cancelled");
        require(escrow.endTimestamp < block.timestamp, "Escrow has not ended");

        if (_user == User.HOST) {
            require(
                escrow.hostState == EscrowMemberState.DEPOSITED,
                "Host has already withdrawn / Hasn't deposited yet"
            );

            require(escrow.host == msg.sender, "Only host can withdraw");

            escrow.state = EscrowState.WITHDRAWN;
            escrow.hostState = EscrowMemberState.WITHDRAWN;

            escrowToken.transfer(msg.sender, escrow.hostDeposit);
        } else {
            require(
                escrow.guestState == EscrowMemberState.DEPOSITED,
                "Guest has already withdrawn / Hasn't deposited yet"
            );

            require(escrow.guest == msg.sender, "Only guest can withdraw");

            escrow.state = EscrowState.WITHDRAWN;
            escrow.guestState = EscrowMemberState.WITHDRAWN;

            escrowToken.transfer(msg.sender, escrow.guestDeposit);
        }

        emit EscrowWithdrawn(
            _escrowId,
            _user == User.HOST ? escrow.hostDeposit : escrow.guestDeposit,
            _user
        );
    }

    function contest(uint256 _escrowId, User _user) external {
        Escrow storage escrow = escrows[_escrowId];

        require(
            escrow.endTimestamp < block.timestamp,
            "Escrow has already ended"
        );

        if (_user == User.HOST) {
            require(escrow.host == msg.sender, "Only host can contest");

            escrow.hostState = EscrowMemberState.CONTESTED;
        } else {
            require(escrow.guest == msg.sender, "Only guest can contest");

            escrow.guestState = EscrowMemberState.CONTESTED;
        }

        escrow.state = EscrowState.CONTESTED;
        emit EscrowContested(_escrowId, _user);
    }

    function resolveContest(
        uint256 _escrowId,
        uint256 _hostPercentage,
        uint256 _guestPercentage
    ) external onlyOwner {
        require(
            _hostPercentage + _guestPercentage == 100,
            "Percentages must add up to 100"
        );

        Escrow storage escrow = escrows[_escrowId];

        require(
            escrow.state == EscrowState.CONTESTED,
            "Escrow is not contested"
        );

        uint256 totalDeposit = escrow.hostDeposit + escrow.guestDeposit;
        uint256 hostAmount = (totalDeposit * _hostPercentage) / 100;
        uint256 guestAmount = (totalDeposit * _guestPercentage) / 100;

        escrowToken.transfer(escrow.host, hostAmount);
        escrow.hostState = EscrowMemberState.WITHDRAWN;

        emit EscrowWithdrawn(_escrowId, hostAmount, User.HOST);

        escrowToken.transfer(escrow.guest, guestAmount);
        escrow.guestState = EscrowMemberState.WITHDRAWN;

        emit EscrowWithdrawn(_escrowId, guestAmount, User.GUEST);

        escrow.state = EscrowState.RESOLVED;
        emit EscrowResolved(_escrowId, _hostPercentage, _guestPercentage);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
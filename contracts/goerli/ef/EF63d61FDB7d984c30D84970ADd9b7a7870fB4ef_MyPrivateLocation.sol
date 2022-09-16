// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyPrivateLocation is Context, Ownable {
    using Counters for Counters.Counter;

    uint8 constant decimalBase = 6;

    mapping(address => Coordinate) private _locations;

    mapping(address => address[]) private _allowances;

    mapping(uint256 => Invitation) private _invitations;

    Counters.Counter private _invitationsCounter;

    struct Coordinate {
        int256 lat;
        int256 long;
    }

    event LocationAdded(address inputAddress);

    enum InvitationState {
        Accepted,
        Declined
    }

    struct Invitation {
        address from;
        address to;
    }

    event CreatedInvitation(uint256 id, address to);

    event AnsweredInvitation(uint256 id, InvitationState state);

    /**
     * Add a location
     */
    function setLocation(int256 lat, int256 long) public {
        _locations[_msgSender()] = Coordinate(lat, long);
        emit LocationAdded(_msgSender());
    }

    /**
     * View a location
     */
    function getLocation(address _address)
        external
        view
        returns (Coordinate memory coordinate)
    {
        if (_msgSender() == _address) {
            return _locations[_address];
        }

        bool isAuthorized = false;

        for (uint256 i = 0; i < _allowances[_address].length; i++) {
            isAuthorized = _msgSender() == _allowances[_address][i];

            if (isAuthorized) {
                break;
            }
        }

        require(isAuthorized, "not authorized to consult location");

        coordinate = _locations[_address];
    }

    /**
     * Allow an user to view your location
     */
    function grant(address _to) public {
        _invitationsCounter.increment();
        _invitations[_invitationsCounter.current()] = Invitation(
            _msgSender(),
            _to
        );

        emit CreatedInvitation(_invitationsCounter.current(), _to);
    }

    /**
     * Accept an user invitation to view his location
     */
    function accept(uint256 _invitationId, bool acceptation) public {

        address _from = _invitations[_invitationId].from;
        address _to = _invitations[_invitationId].to;

        require(
            _invitationId <= _invitationsCounter.current(),
            "Invitation isn't available"
        );

        for (uint256 i = 0; i < _allowances[_from].length; i++) {
            require(
                _allowances[_from][i] != _msgSender(),
                "Already accepted invitation"
            );
        }

        require(
            _to == _msgSender(),
            "You're not granted to view this user location"
        );

        if (!acceptation) {
            emit AnsweredInvitation(_invitationId, InvitationState.Declined);
            return;
        }

        _allowances[_from].push(_msgSender());

        emit AnsweredInvitation(_invitationId, InvitationState.Accepted);
        delete _invitations[_invitationId];
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * We are always using a power of 10 with 6 to view a location as integer
     * For coordinates 45.780446, 4.775158 contract equivalent is 45780446, 4775158
     * To displayed to a user you use the inverse calculation (`4.775158 / 10 ** 6`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {viewLocation} and {setLocation}.
     */
    function decimals() public pure returns (uint8) {
        return decimalBase;
    }

    /**
     * Get the last created invitation
     */
    function lastInvitation() private view returns (uint256) {
        return _invitationsCounter.current();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
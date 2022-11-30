// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkk
kkkxxkkkkkkkkkkkxxxkkkxkkkkkkkkkkOOOOOOOkOOOkkkkkkkkxxkxxxkkxkkkkkkkkkkkkkkkxxkk
kkxkkxxkkkkkkkkxkkkkxxxkkkkOkkdlc:;,,,,,,,;:cloxkOkkkxxxxxkkkkkkkkkkkkkxxxkkkxkk
kkkkkkxxkkkkkkkkkkkkkkkkkxo:,..  ..'',,'''.    .';ldkkkkkkkkkkkkkkkkkkkkkxkxxkkk
kkkkkkkkkkkkkkkkkkkkkkxl;.  .;lddkXNWWWWNNx..co:'. .'cdkOkkkkxkkkkxxkkkkkkkkkkkk
kkkkkkkkkxkkkkkkkkkkxc.  'lxxxKNxkWMMMMMMK; 'oONN0d;. .;dkkkkkxxxxxxxkOkkkkkkkkk
kkkkkkxxxxxkkkkkkkkl.  ;xOd:,c0MMMMMMMMMMXkd,'kWMMMW0l. .;dkkkkxxxkxxkOkkkkkkkkk
kkkkkkxxkxxkkkxkkd,  ,k0l,;xXWMMMMMMMMMMMMWOdKMMMMMMMWKl. .ckOkkkkkkkkkkkkkkkkkk
kkkkkkkxkxxxkkkko. .oXk';kNMMMMMMMMMMMMMMMN0NMMMMMMMMMMWO,  :xkkkkkkxxkkkkkkkkkk
kkkkkkkkkkkkkkko. .xWWKONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  :kOkkxkxxkkkkkkkkkk
kkkkkkkkkkkkkOd. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  ckkxxxkkxxkkkkkkkk
kkkxkkxxkkkkOk;  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. .dOkxxxkxxkkkkkkkk
kkxkkxxxkkxkOd. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  :kkkkkkkkkkkkkkkk
kkkkxxkkxxxkOl. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ,kOkkkkkkkkkkxkkk
kkkkkkkkxkkkkc  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKK00XWk. 'xOkkkkkkkkkxxxkk
kkkkkkkkkkkkOl. :NMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxooolcc:::xNx. 'xOkkkkkkxxxkkxkk
kkkkkkkkkkkkOo. '0MMMMMMMMMMMMWWNNNNNNNXXKOxoc'...,::::::l0No  ;kkkkkkkkkkkkkkkk
kkkkkkxkkkkkkk;  oWMMMWNXKOxxdodoooocoolcc:::,....;::::::lK0' .oOkkkkkkkkkkkkkkk
kkkkkkxxkkkxkOo. .kWXkdlc;....,:::::::lO0Odc:' ..':::::::l0o  ;kOkkxxkkkkkkkkkkk
kkkxkkkkxkkxkkkc. 'OXxc::' ..':::::::cOWWMNkl' ..':::::::dXd  'dOkkkkxkxxkxkkkkk
kkkkxkkkxkkkkkkkc. .xN0o:. ..':::::::oKX0kx0Kd;'.':::cldONMNl  ,xkxxkkkkkxkkkkkk
kkkkkkkkkkkkkkkkko. .c0Oc. ..,::::::l0Nl   .xNX0OkOO0KXWMMMMK, .oOkkkxxkkkkkkkkk
kkkkkkkkkkkkkkkkkkx;. 'kO:...,:::coxKW0'    .oNMMMMMMMMMMMMM0' .oOkkkkkkkkkkkkkk
kkkkkkkkkkxxkkkkxkOk:  lWXOxxxkO0KNWMMO.     ;KMMMMMMMMMMMW0;  :kkkkkkkkkkkkkkkk
kkkkkkkkkkxxxkxxxkkk:  oWMMMMMMMMMMMMMWOoc;:o0WMMMMMMMN0xo:. .cxkkkkkkxxxkxxxkkk
kkkkkkkkkkxxxxxkkkkOl. ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;     ,dkkkkkkkkxxxxxkkkkk
kkkkkkkkkkkkkxkkkkkkk:  ,xXMMMMMMMMMMMMMMMMMMMMMMMMMMx. ;c  cOkkkkkOkkkxxxkkkkkk
kkkkkxxkkkkkkkkkkkkkOkl.  .;cc:;:xNMMMMMMMMMMMMMWX0xc. .kO. ;kOkkkkkkkkkkkkkkkkk
kkxkkxxkkkxkOkkkkkkkkkkxo:,.  ..  c0XDGAPX0Oxdl:,.. .,lKWK, 'xOkkkkkxxxkkkkkkkkk
kkkxkxxkkkkkkkkxkkkxxkkkkkOx, .do. ........  ..';cokKWMMMWc .oOkkkkkxxkxxkkkkkkk
kkkkkkkkkkkOkkkxxkkkkxkkkkkOo. :X0ooloooddxkO0XNWMMMMMMMMWl  cOkkkkxxkkxkkkkkkkk
kkkkkkkkkkOkkkkkkkxxkkkkkkkkk: .dOdNVTQSWDHMMMMMMMMMMMMNk;. 'okkkkkkkkkkkOkkkkkk
kkkkkkkkkkkkkkkkkkxxkkkkkkkkOx' '0WOccoxkOKWMMMMMMMMWKd, .,okkkkkkkkkkkkkkkkkkkk
kkkkkkkkxxkkkkkkkkkkkkkkkkkkkOl. 'clcccc::dXMMMMMN0d:. .:dkkkkkkkkkkkkkxkkkxxkkk
kkOkxxkkkxxxkkkkkkkkkkkkkxxxkkkl;'.....,;:cooool:'. .,lxkkkkkxxkkkkkkkxxxkkkkkkk
kkkkxxxxxxkkxkkkkkkkkkkkxxxxxkkkOkkdoc:;,,'.....';coxkkkkkxxkxxxkkxkkkkxkkkkkkkk
kkkkkkxxxkkkkkkkkkkOkkkxxkkxxkkkkkkkkkOOOkkkkxkkkOOkkkkkkkxxxkxxxkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkklancexwasxherextookkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
*/

/**
 * @title Gumball Machine
 * @author Swag Golf
 */
contract GumballMachine is Ownable, Pausable {

    uint256 public _totalGumballs = 888;
    uint256 public _gumballPrice;
    uint256 public _maxBatchHandleTurns = 10;

    address public _withdrawalAddress;

    uint256 public _nextToDispense = 1;

    event DispenseGumball( address indexed to, uint256 startIndex, uint256 quantity );

    function setGumballPrice(
        uint256 gumballPrice
    )
        external
        onlyOwner 
    {
        _gumballPrice = gumballPrice;
    }

    function setMaxBatchHandleTurns(
        uint256 maxBatchHandleTurns
    )
        external
        onlyOwner 
    {
        _maxBatchHandleTurns = maxBatchHandleTurns;
    }

    constructor( 
        uint256 gumballPrice, 
        uint256 maxBatchHandleTurns,
        address withdrawalAddress )
    {
        _gumballPrice = gumballPrice;
        _maxBatchHandleTurns = maxBatchHandleTurns;
        _withdrawalAddress = withdrawalAddress;

        _pause();
    }

    function turnHandle(
        uint256 turns) 
        external 
        whenNotPaused
        payable
    {
        require( ( _nextToDispense + turns ) <= _totalGumballs, "Turns would exceed gumball supply" );
        require( turns <= _maxBatchHandleTurns, "Attempt to turn handle more than maximum allowed" );
        require( msg.value >= ( turns * _gumballPrice ), "Invalid payment amount" );
        
        emit DispenseGumball( msg.sender, _nextToDispense, turns );

        _nextToDispense += turns;
        
    } 

    function pause() 
        external
        onlyOwner
    {
        _pause();
    }

    function unPause()
        external
        onlyOwner 
    {
        _unpause();
    }

    function setWithdrawalAddress( address newAddress ) 
        external 
        onlyOwner 
    {
        _withdrawalAddress = newAddress;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
        require(success);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
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

// SPDX-License-Identifier: None

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@%(******/(%%%&@@@@@@@@@@@@@&%%%%%&&&&%&@@@@@@@@@@
// @@@@@@@@&(.            .,*%@&/.              ,(%@@@@@@&/.             .#@@@@@@@@
// @@@@@@@@@&%#*.  ./###(,    .(%(*.      ....    ./&@@@%,     ,*,.       /@@@@@@@@
// @@@@@@@@@@@@#,  .(@@@@@%,   .#@&(.   ,#@@@@&*    *%@%,   .(@@@@@%*    .(@@@@@@@@
// @@@@@@@@@@@@(.  ,#@@@@@%*   ,#@@#.   ,#@@@@@@*   ,#@#.  ./&@@@@@@&(.  .#@@@@@@@@
// @@@@@@@@@@@@#,             ,%@@@#,   ,%@@@@@@(.  ./%/   .(@@@@@@@@@&#(#@@@@@@@@@
// @@@@@@@@@@@@#,         .*#&@@@@@#.   ,%@@@@@@(.   *#*   .#@@@@@@@&/. .*%@@@@@@@@
// @@@@@@@@@@@@#,   *@@@@@@@@@@@@@@#,   ,%@@@@@&*   ./&(   .(@@@@@@@%*    /@@@@@@@@
// @@@@@@@@@@@@%,  ./@@@@@@@@@@@@@@%,   *&@@@@&*    *%@%,   ,#@@@@@%*    ,%@@@@@@@@
// @@@@@@@@@@@&(,   *%&@@@@@@@@@@@&(,   .*(/,.     *%@@@@/.   ,,,.      *&@@@@@@@@@
// @@@@@@@@@%,         /&@@@@@@@%*              .,#@@@@@@@&#*        ./%@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Whitelist reservation contract for Prisoner's Dilemma Club
 */
contract WhitelistReservation is Ownable {
    uint256 costToReserve = .2 ether;
    uint256 public constant MAX_RESERVATIONS = 2501; // comparison with less than due to gas savings
    uint256 public reservationCount = 0;
    address public withdrawalAddress;
    address[] public reservationList; // allows the whitelist to be read for inclusion in the merkle tree
    mapping(address => bool) public addressHasReserved; // allows users to check for themselves if they have a reservation

    constructor() {}

    /**
     * Standard fallback function to allow contract to receive payments
     */
    receive() external payable {}

    /**
     * @dev Withdraw all ether from this contract and send to prespecified address
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "Withdrawal address must be set");
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function setWithdrawalAddress(address _address) external onlyOwner {
        withdrawalAddress = _address;
    }

    /**
     * @dev Pay .2 ether to reserve a spot on the PDC presale whitelist
     */
    function reserveWhitelistSpot() external payable {
        require(msg.value == costToReserve, "Incorrect payment amount");
        require(addressHasReserved[msg.sender] == false, "Address already reserved");
        require(reservationCount + 1 < MAX_RESERVATIONS, "Reservations closed");

        reservationCount++;
        addressHasReserved[msg.sender] = true;
        reservationList.push(msg.sender);
    }
}
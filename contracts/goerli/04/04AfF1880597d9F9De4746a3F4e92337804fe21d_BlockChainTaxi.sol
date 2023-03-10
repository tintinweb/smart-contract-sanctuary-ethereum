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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockChainTaxi is Ownable {
    /**
    This is a status variable to detect the status of the taxi
        0 - Taxi is available.
        1 - Searching for driver.
        2 - Driver is on the way.
        3 - Driver has arrived and is waiting.
        4 - Driving
     */
    uint8 public status;
    /**
    The percentage of money that goes back to passenger in case of the ride cancelling
     */
    uint8[5] moneyBackPercentages = [100, 100, 80, 70, 0];
    string rideOrigin;
    string rideDestination;
    uint256 ridePrice;

    //TODO Implement it better with roles see: import "@openzeppelin/contracts/access/AccessControl.sol";
    address passenger;
    address driver;

    function updateStatus(uint8 _status) private {
        require(
            _status <= 4,
            "Status should be not more than 4. Refer to the contract code for more information."
        );
        status = _status;
        emit Status(_status);
    }

    function requestRide(
        string memory _rideOrigin,
        string memory _rideDestination
    ) public payable {
        require(status == 0, "Wrong status");
        (bool success, ) = address(this).call{value: ridePrice}("");
        require(success);
        rideOrigin = _rideOrigin;
        rideDestination = _rideDestination;
        ridePrice = msg.value;
        passenger = msg.sender;
        updateStatus(1); // set status to "Searching for driver"
    }

    function checkRide()
        public
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        return (rideOrigin, rideDestination, ridePrice);
    }

    function acceptRide() public {
        require(status == 1, "Wrong status");
        driver = msg.sender;
        updateStatus(2); // set status to "Driver is on the way"
    }

    function arrived() public {
        require(status == 2, "Wrong status");
        require(msg.sender == driver);
        updateStatus(3);
    }

    function startRide() public {
        require(status == 3, "Wrong status");
        require(msg.sender == driver, "Only driver can call this function");
        updateStatus(4);
    }

    function finishRide() public payable {
        require(status == 4, "Wrong status");
        require(msg.sender == driver);
        (bool success, ) = payable(driver).call{value: ridePrice}("");
        require(success);
        reinitializeVariables();
    }

    function reinitializeVariables() internal {
        updateStatus(0); // set status to "Taxi is available"
        rideOrigin = "";
        rideDestination = "";
        ridePrice = 0;
        driver = address(0);
        passenger = address(0);
    }

    function returnPayment() internal {
        uint256 returnAmount = (moneyBackPercentages[status] * ridePrice) / 100;
        uint256 driverAmount = ridePrice - returnAmount;
        (bool successPassenger, ) = payable(passenger).call{
            value: returnAmount
        }("");
        require(successPassenger);
        (bool successDriver, ) = payable(driver).call{value: driverAmount}("");
        require(successDriver);
    }

    function cancelRidePassenger() public payable {
        /// ! this is not safe, it's just for demo purposes otherwise the demo will be stuck
        // require(
        //     msg.sender == passenger && passenger != address(0),
        //     "Only assigned passenger can call this function"
        // );
        returnPayment();
        reinitializeVariables();
    }

    function cancelRideDriver() public payable {
        require(
            msg.sender == driver && driver != address(0),
            "Only assigned driver can call this function"
        );
        updateStatus(0); // We update status to 0, in order to return all funds to passenger
        returnPayment();
        reinitializeVariables();
    }

    function cancelRideOwner() public onlyOwner {
        reinitializeVariables();
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

    function setStatus(uint8 _status) public onlyOwner {
        require(
            _status <= 4,
            "Status should be not more than 4. Refer to the contract code for more information."
        );
        status = _status;
        emit Status(_status);
    }

    event Status(uint8 indexed updatedStatus);

    receive() external payable {}
}
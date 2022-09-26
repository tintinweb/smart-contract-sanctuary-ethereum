/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/RentACar.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

///@imports


/// @title A Car Rental Smart Contract
///@notice Allows renter to rent a car

contract CarRental is ReentrancyGuard {
    struct Renter {
        address walletAddress;
        string name;
        bool active;
        bool canRent;
        uint start;
        uint end;
        uint due;
    }

    address immutable owner;

    mapping(address => Renter) private renters;

    event Receive(string func, address sender, uint value, bytes data);
    event RenterAdded(string name, address renterAddress, uint time);
    event Withdraw(address to, uint time);
    event BikeOut(address indexed who, uint time);
    event BikeIn(address indexed who, uint time);
    event DuePaid(address indexed who, uint amount, uint time);

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Receive("fallback", msg.sender, msg.value, "");
    }

    function addRenter(
        address _walletAddress,
        string memory _name,
        bool _active,
        bool _canRent,
        uint _start,
        uint _end,
        uint _due
    ) external {
        renters[_walletAddress] = Renter(
            _walletAddress,
            _name,
            _active,
            _canRent,
            _start,
            _end,
            _due
        );
        emit RenterAdded(_name, _walletAddress, block.timestamp);
    }

    function takingOut(address _walletAddress) public {
        require(
            renters[_walletAddress].walletAddress == msg.sender,
            "please only use your wallet Address"
        );
        require(
            renters[_walletAddress].due == 0,
            "you have to clear your dues first"
        );
        require(
            renters[_walletAddress].canRent == true,
            "you have an active session or you have to clear your dues"
        );
        Renter storage renter = renters[_walletAddress];
        renter.active = true;
        renter.start = block.timestamp;
        renter.canRent = false;
        emit BikeOut(msg.sender, block.timestamp);
    }

    function returning(address _walletAddress) public {
        require(
            renters[_walletAddress].walletAddress == msg.sender,
            "please only use your wallet Address"
        );
        require(
            renters[_walletAddress].active == true,
            "please take Out a bike first"
        );
        Renter storage renter = renters[_walletAddress];
        renter.active = false;
        renter.end = block.timestamp;
        renter.canRent = true;
        totalDue(_walletAddress);
        emit BikeIn(msg.sender, block.timestamp);
    }

    function withdrawBalance() external nonReentrant onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        emit Withdraw(msg.sender, block.timestamp);
    }

    function payDue(address _walletAddress) public payable {
        require(renters[_walletAddress].due > 0, "you don't have any dues");
        require(
            renters[_walletAddress].active == false,
            "please return bike and pay"
        );
        require(
            msg.value >= renters[_walletAddress].due,
            "Please enter the exact due amount"
        );
        Renter storage renter = renters[_walletAddress];
        renter.due -= msg.value;
        renter.canRent = true;
        renter.due = 0;
        renter.start = 0;
        renter.end = 0;
        emit DuePaid(msg.sender, msg.value, block.timestamp);
    }

    function dueOfRide(address _walletAddress) public view returns (uint) {
        require(
            renters[_walletAddress].canRent == true,
            "your session is active please checkIn"
        );
        require(
            renters[_walletAddress].active == false,
            "your session is active please checkIn or please checkout  to see Due "
        );
        return renters[_walletAddress].due;
    }

    function balanceOfContract() public view returns (uint) {
        return address(this).balance;
    }

    function totalDue(address _walletAddress) internal {
        require(
            renters[_walletAddress].active == false,
            "you have active session please return bike to get due"
        );
        uint finaldue = renters[_walletAddress].due +
            costOfRide(_walletAddress);
        renters[_walletAddress].due = finaldue;
    }

    function timeDifference(uint _end, uint _start)
        internal
        pure
        returns (uint256)
    {
        return _end - _start;
    }

    ///@dev converting timestamps to minutes

    function rideTime(address _walletAddress) internal view returns (uint256) {
        uint rideDuration = timeDifference(
            renters[_walletAddress].end,
            renters[_walletAddress].start
        );
        uint rideDurationMin = rideDuration / 60;
        return (rideDurationMin);
    }

    function costOfRide(address _walletAddress) private view returns (uint) {
        uint costPerMinute = 50000000000; //just typed as many zeroes as i wanted ;)
        return rideTime(_walletAddress) * costPerMinute;
    }
}
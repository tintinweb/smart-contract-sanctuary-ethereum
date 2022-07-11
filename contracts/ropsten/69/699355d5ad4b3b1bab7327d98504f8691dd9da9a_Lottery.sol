/**
 *Submitted for verification at Etherscan.io on 2022-07-11
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

// File: contracts/Lottery.sol


pragma solidity ^0.8.0;


/// @title Lottery
/// @author Sabantsev Aleksandr @sabantsev92
/// @notice The last bettor can take the winnings 90% if there is no other bet within an hour
contract Lottery is ReentrancyGuard {
    address public winer;
    uint256 public timestamp;
    uint256 constant TIME_TO_WIN = 1 hours;

    /// @notice Triggered when winnings are withdrawn
    /// @param winner The address of the winner
    /// @param amount The win size
    event Win(address indexed winner, uint amount);
    /// @notice Triggered when the bet was placed
    /// @param player The address of the player who placed the bet
    /// @param amount The bet size
    event Bet(address indexed player, uint amount);

    /// @notice Accepting a bet. The rate must be at least one percent of the available amount
    receive() external payable {
        require(msg.value >= (address(this).balance / 100) && msg.value >= 1, "Too little money");
        timestamp = block.timestamp;
        winer = msg.sender;
        emit Bet(msg.sender, msg.value);
    }

    /// @notice You can take the winnings if you win
    function takeTheWinnings() external nonReentrant() {
        require(msg.sender == winer, "Address not winer");
        require(block.timestamp >= timestamp + TIME_TO_WIN, "Too little time has passed");
        bool check = payable(msg.sender).send((address(this).balance * 9) / 10);
        require(check, "Error");
        winer = address(0x0);
        emit Win(msg.sender, (address(this).balance * 9) / 10);
    }

    /// @notice Shows how much money is currently on the contract
    /// @return Returns how much money is currently on the contract
    function currentBalance() public view returns(uint) {
        return address(this).balance;
    }

}
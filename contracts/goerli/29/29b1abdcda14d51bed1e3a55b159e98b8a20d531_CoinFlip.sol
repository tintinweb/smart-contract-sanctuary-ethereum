/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/coinflip.sol


pragma solidity ^0.8.4;



contract CoinFlip is Ownable, ReentrancyGuard {
    uint256 payPercentage = 90;

    // Maximum amount to bet in WEIs
    uint256 public MaxAmountToBet = 200000000000000000; // = 0.2 Ether

    struct Game {
        address addr;
        uint256 blocknumber;
        uint256 blocktimestamp;
        uint256 bet;
        uint256 prize;
        bool winner;
    }

    Game[] lastPlayedGames;

    Game newGame;

    event Status(string _msg, address user, uint256 amount, bool winner);

    function Play() public payable {
        if (msg.value > MaxAmountToBet) {
            revert();
        } else {
            if ((block.timestamp % 2) == 0) {
                if (
                    address(this).balance <
                    (msg.value * ((100 + payPercentage) / 100))
                ) {
                    // We don't have enough funds to pay the prize, so we transfer everything we have
                    (bool hs, ) = payable(msg.sender).call{
                        value: address(this).balance
                    }("");
                    require(hs);
                    emit Status(
                        "Congratulations, you win! Sorry, we didn't have enought money, we will deposit everything we have!",
                        msg.sender,
                        msg.value,
                        true
                    );

                    newGame = Game({
                        addr: msg.sender,
                        blocknumber: block.number,
                        blocktimestamp: block.timestamp,
                        bet: msg.value,
                        prize: address(this).balance,
                        winner: true
                    });
                    lastPlayedGames.push(newGame);
                } else {
                    uint256 _prize = (msg.value * (100 + payPercentage)) / 100;
                    emit Status(
                        "Congratulations, you win!",
                        msg.sender,
                        _prize,
                        true
                    );
                    (bool hs, ) = payable(msg.sender).call{value: _prize}("");
                    require(hs);

                    newGame = Game({
                        addr: msg.sender,
                        blocknumber: block.number,
                        blocktimestamp: block.timestamp,
                        bet: msg.value,
                        prize: _prize,
                        winner: true
                    });
                    lastPlayedGames.push(newGame);
                }
            } else {
                emit Status("Sorry, you loose!", msg.sender, msg.value, false);

                newGame = Game({
                    addr: msg.sender,
                    blocknumber: block.number,
                    blocktimestamp: block.timestamp,
                    bet: msg.value,
                    prize: 0,
                    winner: false
                });
                lastPlayedGames.push(newGame);
            }
        }
    }

    function getGameCount() public view returns (uint256) {
        return lastPlayedGames.length;
    }

    function getGameEntry(uint256 index)
        public
        view
        returns (
            address addr,
            uint256 blocknumber,
            uint256 blocktimestamp,
            uint256 bet,
            uint256 prize,
            bool winner
        )
    {
        return (
            lastPlayedGames[index].addr,
            lastPlayedGames[index].blocknumber,
            lastPlayedGames[index].blocktimestamp,
            lastPlayedGames[index].bet,
            lastPlayedGames[index].prize,
            lastPlayedGames[index].winner
        );
    }

    function depositFunds(uint256 amount) public payable onlyOwner {
        (bool hs, ) = payable(address(this)).call{value: amount}("");
        require(hs);
        emit Status(
            "User has deposit some money!",
            msg.sender,
            msg.value,
            true
        );
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        (bool hs, ) = payable(msg.sender).call{value: amount}("");
        require(hs);
        emit Status("User withdraw some money!", msg.sender, amount, true);
    }

    function setMaxAmountToBet(uint256 amount)
        public
        onlyOwner
        returns (uint256)
    {
        MaxAmountToBet = amount;
        return MaxAmountToBet;
    }

    function getMaxAmountToBet() public view returns (uint256) {
        return MaxAmountToBet;
    }

    function Kill() public onlyOwner {
        emit Status(
            "Contract was killed, contract balance will be send to the owner!",
            msg.sender,
            address(this).balance,
            true
        );
        address payable owner = payable(msg.sender);
        selfdestruct(owner);
    }
}
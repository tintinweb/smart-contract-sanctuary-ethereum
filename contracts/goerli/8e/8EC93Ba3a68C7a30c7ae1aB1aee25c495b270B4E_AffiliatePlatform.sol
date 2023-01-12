/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: GPL-3.0
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/AffiliatePlatform.sol

pragma solidity >=0.7.0 <0.9.0;

contract AffiliatePlatform is Ownable, ReentrancyGuard {
    struct Splitter {
        address _to;
        uint256 percent;
    }

    struct Order {
        uint256 _type;
        uint256 _count;
    }

    // EVENTS
    event Buy(address indexed _from, Order[] order);
    event Received(address, uint256);

    mapping(uint256 => uint256) private prices;

    uint256 private WIDGET_TYPE = 1;
    uint256 private HOSTING_TYPE = 2;

    Splitter[] private splitters;

    constructor() {
        // Set costs
        prices[WIDGET_TYPE] = 0.175 ether;
        prices[HOSTING_TYPE] = 0.375 ether;

        // Set splitters
        splitters.push(
            Splitter(0x20fD84614140C030aE4c38512305e623c79082e3, 20)
        );
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Buy campaign
     */
    function buy(Order[] calldata order) public payable nonReentrant {
        uint256 cost = 0;

        for (uint256 i = 0; i < order.length; i++) {
            cost += prices[order[i]._type] * order[i]._count;
        }

        require(cost <= msg.value, "Insufficient funds");
        emit Buy(msg.sender, order);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        for (uint256 i = 0; i < splitters.length; i++) {
            uint256 amount = (balance * splitters[i].percent) / 100;
            (bool r, ) = payable(splitters[i]._to).call{value: amount}("");
            require(r);
        }

        (bool s, ) = payable(owner()).call{value: address(this).balance}("");
        require(s);
    }

    /**
     * @dev Add/Update cost
     */
    function setCost(uint256 _type, uint256 _cost)
        public
        nonReentrant
        onlyOwner
    {
        prices[_type] = _cost;
    }

    /**
     * @dev Add new splitter or update percent for an existing one
     */
    function setSplitter(address _to, uint256 percent)
        public
        onlyOwner
        nonReentrant
    {
        bool isNew = true;

        for (uint256 i = 0; i < splitters.length; i++) {
            if (splitters[i]._to == _to) {
                splitters[i].percent = percent;
                isNew = false;
            }
        }

        if (isNew) splitters.push(Splitter(_to, percent));
    }

    /**
     * @dev Returns array with costs
     */
    function getCosts(uint256[] memory costIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory costs = new uint256[](costIds.length);

        for (uint256 i = 0; i < costIds.length; i++) {
            costs[i] = (prices[costIds[i]]);
        }

        return costs;
    }

    /**
     * @dev Get count of splitters
     */
    function getLengthSplitters() public view onlyOwner returns (uint256) {
        return splitters.length;
    }
}
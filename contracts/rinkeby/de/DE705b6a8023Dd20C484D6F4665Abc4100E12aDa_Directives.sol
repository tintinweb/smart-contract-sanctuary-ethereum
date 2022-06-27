// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import './params/Index.sol';


contract Directives is Params {
    
    constructor(Constructor.Struct memory input) Params(input) {}

    function createRewardsBatch(Reward.Struct[] memory batch) external onlyOwner {
        (bool success,) = control.restricted.delegatecall(msg.data);
        require(success);
    }

    function createPaymentsBatch(Payment.Struct[] memory batch) external onlyOwner {
        (bool success,) = control.restricted.delegatecall(msg.data);
        require(success);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '@openzeppelin/contracts/access/Ownable.sol';
import './Constructor.sol';
import './Payment.sol';
import './Reward.sol';


contract Params is Ownable {

    event NewPaymentBatch(uint256 indexed id, Payment.Struct[] payments);
    event NewRewardBatch(uint256 indexed id, Reward.Struct[] rewards);

    uint256 public paymentId = 1;
    uint256 public rewardId = 1;
    Constructor.Struct public control;
    mapping(uint256 => Payment.Struct[]) public payments;
    mapping(uint256 => Reward.Struct[]) public rewards;

    constructor(Constructor.Struct memory input) {
        control = input;
    }

    function setGlobalParameters(Constructor.Struct memory globalParameters) external onlyOwner {
        control = globalParameters;
    }

    function getPayments(uint256 id) external view returns(Payment.Struct[] memory) {
        return payments[id];
    }

    function getRewards(uint256 id) external view returns(Reward.Struct[] memory) {
        return rewards[id];
    }

    fallback() external payable {}
    receive() external payable {}

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
pragma solidity <=0.8.15;

library Constructor {
    struct Struct {
        address restricted;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;


library Payment {
    
    struct Struct {
        address from;
        address payable to;
        address currency;
        uint256[] ids;
        uint256[] amounts;
        uint256 id;
        uint256 amount;
        // 0 - erc721
        // 1 - erc1155
        // 2 - erc20
        // 3 - ETH payment
        uint32 paymentType;
        uint32 percentageWon;
        uint32 place;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.15;
import './Payment.sol';

library Reward {
    
    struct Struct {

        Payment.Struct payment;

        // Max and Min amount to be given, otherwise set on 0
        uint256 maxAmount;
        uint256 minAmount;

        // Valability time interval if it's the case, otherwise set on 0 both
        uint256 dateStart;
        uint256 dateStop;

        // 1 - ETH
        // 2 - ERC20
        // 3 - ERC721
        // 4 - ERC1155
        uint32 rewardType;

        // Set on true if winners can get this custom reward too
        bool forWinners;
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
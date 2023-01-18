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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IRDS.sol";
import "../interface/IERC20TokenBank.sol";

contract USDTAirdrop is Ownable {
    IRDS public rds;
    IERC20TokenBank public usdtBank;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalAward;
    uint256 public creationBlock;
    mapping(address => bool) public claimed;

    constructor(
        address _rdsAddr,
        address _usdtBank,
        uint256 _totalAward,
        uint256 _startAt,
        uint256 _endAt
    ) {
        rds = IRDS(_rdsAddr);
        usdtBank = IERC20TokenBank(_usdtBank);
        totalAward = _totalAward * 10**6;
        startTime = _startAt;
        endTime = _endAt;
        require(startTime < endTime, "invalid input!");
        creationBlock = _startAt;
    }

    event Claim(address indexed addr, uint256 amount);

    modifier isDuringAirdrop(bool _is) {
        if (_is) {
            require(
                block.number > startTime && block.number < endTime,
                "not started or already ended"
            );
        } else {
            require(
                block.number < startTime || block.number > endTime,
                "during airdrop"
            );
        }
        _;
    }

    function claim() external isDuringAirdrop(true) {
        uint256 amount = (rds.balanceOfAt(msg.sender, creationBlock) *
            totalAward) / rds.totalSupplyAt(creationBlock);
        require(amount > 0, "no airdrop");
        require(!claimed[msg.sender], "already claimed");
        claimed[msg.sender] = true;
        bool success = usdtBank.issue(msg.sender, amount);
        require(success);

        emit Claim(msg.sender, amount);
    }

    function changeParams(uint256 _creationBlock, uint256 _totalAward)
        external
        isDuringAirdrop(false)
        onlyOwner
    {
        creationBlock = _creationBlock;
        totalAward = _totalAward;
    }

    function changePeriod(uint256 _startAt, uint256 _endAt) external onlyOwner {
        startTime = _startAt;
        endTime = _endAt;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20TokenBank {
    function issue(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRDS {
    function totalSupplyAt(uint256 _blockNumber)
        external
        view
        returns (uint256);

    function balanceOfAt(address _owner, uint256 _blockNumber)
        external
        view
        returns (uint256);
}
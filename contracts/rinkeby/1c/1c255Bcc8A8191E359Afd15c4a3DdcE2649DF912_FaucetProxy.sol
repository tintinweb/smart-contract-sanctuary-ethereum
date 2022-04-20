// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBEP20Proxy.sol";

contract FaucetProxy is Ownable {
    bool public is_pause;

    // block.timestamp => seconds
    // set 5mins as default
    uint256 public faucet_duration = 0; 

    // MAX faucet amount
    uint256 public MAX_FAUCET_AMOUNT = 10**7 * 10 ** 18;

    mapping(address => uint256) public last_faucet_ts;

    modifier notPaused {
        require(is_pause == false, "Faucet paused");
        _;
    }
    
    modifier mintable {
        if (last_faucet_ts[msg.sender] != 0) {
            require(block.timestamp - last_faucet_ts[msg.sender] >= faucet_duration, "You request token too often");
        }
        _;
    }

    function request_token(address token_address, uint256 amount) mintable external {
        require(MAX_FAUCET_AMOUNT >= amount, "You requested too much tokens");

        IBEP20Faucet token = IBEP20Faucet(token_address);
        token.proxyMint(msg.sender, amount);
        last_faucet_ts[msg.sender] = block.timestamp;
    }

    function admin_faucet(address recipient, address token_address, uint256 amount) external onlyOwner {
        IBEP20Faucet token = IBEP20Faucet(token_address);
        token.proxyMint(recipient, amount);
        last_faucet_ts[recipient] = block.timestamp;
    }

    // block.timestamp => seconds
    // set 5mins as default
    function set_faucet_duration(uint256 _duration) external onlyOwner {
        require(faucet_duration != _duration, "this value has been already set");
        faucet_duration = _duration;
    }

    function set_max_amount(uint256 _amount) external onlyOwner {
        require(MAX_FAUCET_AMOUNT != _amount, "this value has been already set");
        MAX_FAUCET_AMOUNT = _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20Faucet {
    function proxyMint(address recipient, uint256 amount) external;
    function proxyBurn(address recipient, uint256 amount) external;
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
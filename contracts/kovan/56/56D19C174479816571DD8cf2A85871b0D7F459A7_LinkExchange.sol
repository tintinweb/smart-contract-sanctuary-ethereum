// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IExchange.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LinkExchange is IExchange, Ownable {
    mapping(address => mapping(address => uint)) public liquidity;
    event SetLiquidity(address indexed _token0, address indexed _token1, uint _liquidity0, uint _liquidity1);

    struct Config {
        address token0;
        address token1;
        uint liquidity0;
        uint liquidity1;
    }

    function setLiquidity(Config calldata _config) external onlyOwner {
        liquidity[_config.token0][_config.token1] = _config.liquidity0;
        liquidity[_config.token1][_config.token0] = _config.liquidity1;
        emit SetLiquidity(_config.token0, _config.token1, _config.liquidity0, _config.liquidity1);
    }

    function setListLiquidity(Config[] calldata _listPrice) external onlyOwner {
        for (uint i = 0; i < _listPrice.length; i++) {
            Config calldata _config = _listPrice[i];
            liquidity[_config.token0][_config.token1] = _config.liquidity0;
            liquidity[_config.token1][_config.token0] = _config.liquidity1;
        }
    }

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        override
        returns (uint[] memory amounts)
    {
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = (amountIn * liquidity[path[1]][path[0]]) / liquidity[path[0]][path[1]];
    }

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        override
        returns (uint[] memory amounts)
    {
        amounts = new uint[](2);
        amounts[0] = (amountOut * liquidity[path[0]][path[1]]) / liquidity[path[1]][path[0]];
        amounts[1] = amountOut;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IExchange {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
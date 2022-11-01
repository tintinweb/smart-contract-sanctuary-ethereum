// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAO} from "./interfaces/IDAO.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JoinDAOContract {
    struct Pool { address token_address; uint256 price; address owner_of; }
    mapping(address => bool) private _exists;
    mapping(address => Pool) private _pools;
    address private _dao_builder_address;

    event poolCreated(address token_address, uint256 price, address creator);
    event bought(address token_address, uint256 amount, uint256 amount_paid);

    function createNewDAOPool(address token_address_, uint256 price_, address creator_) public {
        require(token_address_ == msg.sender, "Permission denied");
        require(!_exists[token_address_], "Already exists");
        _pools[token_address_] = Pool(token_address_, price_, creator_);
        emit poolCreated(token_address_, price_, creator_);
    }

    function buy(address token_address_, uint256 amount_) public payable {
        require(_exists[token_address_], "Not exists");
        Pool memory pool = _pools[token_address_];
        require(msg.value >= pool.price * amount_ / 1 ether  , "Not enough funds send");
        IERC20(token_address_).transfer(msg.sender, amount_);
        payable(pool.owner_of).transfer(msg.value);
        emit bought(token_address_, amount_, msg.value);
    }

    function removeLiquidity(address token_address_) public {
        require(_exists[token_address_], "Not exists");
        require(_pools[token_address_].owner_of == msg.sender, "Permission denied");
        IERC20(token_address_).transfer(msg.sender, IERC20(token_address_).balanceOf(address(this)));
    }

    function setPrice(address token_address_, uint256 price_) public {
        require(_exists[token_address_], "Not exists");
        require(_pools[token_address_].owner_of == msg.sender, "Permission denied");
        _pools[token_address_].price = price_;
    }

    function setTokenOwner(address token_address_, address owner_of_) public {
        require(_pools[token_address_].owner_of == msg.sender, "Permission denied");
        _pools[token_address_].owner_of = owner_of_;
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDAO {
    function getDaosByOwner(address owner_of)
        external
        returns (address[] memory);

    function getDaoOwner(address dao_address)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
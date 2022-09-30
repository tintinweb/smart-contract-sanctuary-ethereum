// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne
 * @title DaoAllocation
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract DaoAllocation is Pausable {
    struct Allocation { uint256 uid; address owner_of; address erc20address; uint256 amount; uint256 min_purchase; uint256 max_purchase; uint256 sold_amount; uint256 price; uint256 end_time; }
    struct Metadata { string name; string description; string file_uri;}
    
    Allocation[] private _allocations;

    /**
    * @dev setup owner of this contract.
    */
    constructor (address owner_of_) Pausable(owner_of_) {}

    /**
    * @dev emits when new allocation was created.
    */
    event allocationCreated(uint256 uid, address owner_of, address erc20address, uint256 amount, uint256 price, uint256 min_purchase, uint256 max_purchase, uint256 sold_amount, string wallpaper_uri, string description, string name, uint256 end_time);

    /**
    * @dev emits when someone claims allocation.
    */
    event claimed(uint256 allocation_uid, uint256 sold_amount, address eth_address);

    /**
    * @dev emits when creator of allocation withdraw allocation.
    */
    event withdrawed(uint256 allocation_uid, uint256 amount);

    /**
    * @dev function which creates allocation with params.
    * @param amount amount of ERC20 tokens which you will stake for allocation.
    * @param erc20address token address of ERC20 which you will stake for allocation.
    * @param min_purchase upper limit for claiming for every user.
    * @param max_purchase upper limit for claiming for every user.
    * @param price upper limit for claiming for every user.
    * @param period time in UNIX format which means how long should allocation runs.
    * @param metadata includes name of allocation, description and link to image
    */
    function createAllocation(uint256 amount, address erc20address, uint256 min_purchase, uint256 max_purchase, uint256 price, uint256 period, Metadata memory metadata) public notPaused {
        require(amount > min_purchase, "Min. purchase is greater than total amount");
        require(amount > max_purchase, "Max. purchase is greater than total amount");
        uint256 end_time = block.timestamp + period;
        uint256 newAllocationUid = _allocations.length;
        _allocations.push(Allocation(newAllocationUid, msg.sender, erc20address, amount, min_purchase, max_purchase, 0, price, end_time));
        IERC20(erc20address).transferFrom(msg.sender, address(this), amount);
        emit allocationCreated(newAllocationUid, msg.sender, erc20address, amount, price, min_purchase, max_purchase, 0, metadata.file_uri, metadata.description, metadata.name, end_time);
    }

    /**
    * @dev function which creates allocation with params.
    * @param allocation_uid unique id of allocation which you want claim.
    * @param amount amount of ERC20 tokens which you wan't to claim (should be less then "max_purchase" and greater than "min_purchase").
    */
    function claim(uint256 allocation_uid, uint256 amount) public payable notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        require(allocation.min_purchase <= amount, "Not enough tokens for buy");
        require(allocation.max_purchase >= amount, "Too much tokens for buy");
        require(block.timestamp < allocation.end_time, "Finished");
        require(allocation.sold_amount + amount <= allocation.amount, "Limit exeeded");
        require(msg.value >= (amount * allocation.price) / 1 ether, "Not enough funds send");
        IERC20(allocation.erc20address).transfer(msg.sender, amount * 977 / 1000);
        IERC20(allocation.erc20address).transfer(_owner_of, amount * 3 / 1000);
        _allocations[allocation_uid].sold_amount += amount;
        payable(_allocations[allocation_uid].owner_of).transfer(msg.value);
        emit claimed(allocation_uid, amount, msg.sender);
    }

    /**
    * @dev function which creates allocation with params.
    * @param allocation_uid unique id of allocation which you want claim.
    */
    function withdraw(uint256 allocation_uid) public notPaused {
        Allocation memory allocation = _allocations[allocation_uid];
        require(msg.sender == allocation.owner_of, "No permission");
        require(allocation.end_time < block.timestamp, "Not Finished");
        uint256 amount = allocation.amount - allocation.sold_amount;
        _allocations[allocation_uid].sold_amount = allocation.amount;
        IERC20(allocation.erc20address).transfer(msg.sender, amount);
        emit withdrawed(allocation_uid, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
    }
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
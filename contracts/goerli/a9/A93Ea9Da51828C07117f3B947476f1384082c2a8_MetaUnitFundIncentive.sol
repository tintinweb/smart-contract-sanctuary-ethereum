// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne
 * @title MetaUnitFundIncentive
 * @notice Manages token distribution to funds 
 */
contract MetaUnitFundIncentive is Pausable {
    struct Staking { address eth_address; uint256 amount; }

    address private _meta_unit_address;

    mapping(address => bool) private _white_list_addresses;
    mapping(address => uint256) private _staking_amounts;
    mapping(address => uint256) private _staking_intervals;
    mapping(address => uint256) private _staking_counters;

    /**
    * @dev setup MetaUnit address and owner of this contract
    */
    constructor(address meta_unit_address_, address owner_of_) Pausable(owner_of_) {
        _meta_unit_address = meta_unit_address_;
    }

    /**
    * @dev function allows you to add new user addresses to the white list
    * @param addresses list of funds addresses and thier parts of MetaUnit
    * @param setter boolean value of action
    */
    function setWhiteList(Staking[] memory addresses, bool setter) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            _white_list_addresses[addresses[i].eth_address] = setter;
            _staking_amounts[addresses[i].eth_address] = addresses[i].amount;
        }
    }

    /**
    * @dev function allows claiming of metaunits under established conditions
    */
    function claim() public notPaused {
        require(_white_list_addresses[msg.sender], "You are not in white list");
        require(_staking_intervals[msg.sender] + 30 days <= block.timestamp, "Intervals between claiming should be 30 days");
        require(_staking_counters[msg.sender] < 13, "You can claim metaunit only 12 times");
        if (_staking_counters[msg.sender] < 12) {
            IERC20(_meta_unit_address).transfer(msg.sender, _staking_amounts[msg.sender] / 50);
        } else {
            IERC20(_meta_unit_address).transfer(msg.sender, _staking_amounts[msg.sender]);
        }
        _staking_intervals[msg.sender] = block.timestamp;
        _staking_counters[msg.sender] += 1;
    }
    
    /**
    * @dev function allows withdrawing all MetaUnit from current contract to owner
    */
    function withdraw() public {
        require(_owner_of == msg.sender, "Permission address");
        IERC20 token = IERC20(_meta_unit_address);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
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
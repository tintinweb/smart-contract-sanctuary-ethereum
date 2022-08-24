// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";


// -=-=-=- PONZI LINE v1 [king.code] -=-=-=- \\
contract PonziLine is Ownable{
    uint256 public constant PAY_RATE_PCT = 200;
    uint256 public constant PAY_MASTER_PCT = 10;

    uint256 public _investor_count;
    uint256 public _amt_input_total;
    uint256 public _amt_payout;
    uint256 public _pay_idx;

    bool public _is_open;

    Master public master;

    mapping(uint256 => Investor) public investors;

    struct Investor {
        address payable id;
        uint256 input;      // amount paid in
        uint256 due;        // amount due
        uint256 output;     // amount paid out
        uint256 collected;  // amount withdrawn

    }

    struct Master {
        address payable id;
        uint256 output;
    }

    constructor(){
        _is_open = true;
        _investor_count = 0;
        _amt_payout = 0;
        _pay_idx = 0;

        master.id = payable(msg.sender);
        master.output = 0;
    }

    function notContract(address _addr) private view returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function invest() public payable
    {
        require(_is_open, "Contract is closed");
        require(notContract(msg.sender), "Investor cannot be a contract");
        require(msg.value>0, "Message value must be positive");
        _investor_count += 1;

        investors[_investor_count] = Investor(
            payable(msg.sender),            // id
            msg.value,                      // input
            msg.value*PAY_RATE_PCT/100,     // due
            0,                              // output
            0                               // collected
        );

        _amt_input_total += msg.value;
        
        uint256 master_value = msg.value*PAY_MASTER_PCT/100;
        master.output += master_value;

        _amt_payout += msg.value-master_value;

        while( investors[_pay_idx].due <= _amt_payout){
            investors[_pay_idx].output = investors[_pay_idx].due;
            _amt_payout -= investors[_pay_idx].due;
            _pay_idx += 1;
        }

    }

    function withdraw(uint256 investor_idx) public{
        require(notContract(msg.sender), "Investor cannot be a contract");
        require(investors[investor_idx].id == msg.sender, "Sender is not the investor");
        require(investors[investor_idx].output == investors[investor_idx].due, "Investor has no payout");
        require(investors[investor_idx].collected==0, "Investor has already collected");

        investors[investor_idx].collected = investors[investor_idx].due;
        payable(investors[investor_idx].id).transfer(investors[investor_idx].due);
    }

    function withdrawMaster() public onlyOwner{
        require(master.output>0, "No value to withdraw");

        master.id.transfer(master.output);
        master.output = 0;
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
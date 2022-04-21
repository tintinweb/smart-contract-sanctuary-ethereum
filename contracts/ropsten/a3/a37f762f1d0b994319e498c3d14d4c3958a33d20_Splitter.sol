/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

//pragma solidity ^0.4.11;
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/// @title Splitter
/// @author 0xcaff (Martin Charles)
/// @notice An ethereum smart contract to split received funds between a number
/// of outputs.
contract Splitter is Ownable {

    //mapping between share holders wallet and percentage of royalties
    mapping(address => uint256) shares;

    mapping(address => uint256) withdrawAmount;

    // The total amount of funds which has been deposited into the contract. 
    uint256 public totalRoyalty;

    // royalty holders
    address ADDRESS_1 = 0x7aB924A136ad42A23E3fD1971109aa1AB7D74924;
    address ADDRESS_2 = 0x150bDE4355801e95d0aad21A5587dc2e6E6785BE;
    address ADDRESS_3 = 0x7845337716B6BDA8dDad1d0480Dcdd8bdeB1441F;
    
    receive() external payable {
        totalRoyalty += msg.value;
        distributeRoyalty();
    }

    constructor() payable{
        shares[ADDRESS_1] = 10;
        shares[ADDRESS_2] = 20;
        shares[ADDRESS_3] = 70;
        totalRoyalty += msg.value;
    }


    function distributeRoyalty() internal{
        withdrawAmount[ADDRESS_1] = (msg.value * shares[ADDRESS_1])/100;
        withdrawAmount[ADDRESS_2] = (msg.value * shares[ADDRESS_2])/100;
        withdrawAmount[ADDRESS_3] = (msg.value * shares[ADDRESS_3])/100;
    }

    function withdrawRoyalty() public {
        require(withdrawAmount[msg.sender] > 0 , "no amount found");
        require(payable(msg.sender).send(withdrawAmount[msg.sender]));
    }


    // // Mapping between addresses and how much money they have withdrawn. This is
    // // used to calculate the balance of each account. The public keyword allows
    // // reading from the map but not writing to the map using the
    // // amountsWithdrew(address) method of the contract. It's public mainly for
    // // testing.
    // mapping(address => uint) public amountsWithdrew;

    // // A set of parties to split the funds between. They are initialized in the
    // // constructor.
    // mapping(address => bool) public between;

    // // The number of ways incoming funds will we split.
    // uint public count;

    // // The total amount of funds which has been deposited into the contract.
    // uint public totalInput;

    // // mapping to hold wallet addresses and their royalties percentage eg : 0.1 is 10% , 0.2 is 20%
    // mapping(address => uint256) royaltiesShares;

    // // This is the constructor of the contract. It is called at deploy time.

    // /// @param addrs The address received funds will be split between.
    // constructor(address[] memory addrs , uint256[] memory shares) {
    //     // Contracts can be deployed to addresses with ETH already in them. We
    //     // want to call balance on address not the balance function defined
    //     // below so a cast is necessary.
    //     totalInput = address(this).balance;

    //     count = addrs.length;

    //     for (uint i = 0; i < addrs.length; i++) {
    //         // loop over addrs and update set of included accounts
    //         address included = addrs[i];
    //         between[included] = true;
    //         royaltiesShares[included] = shares[i];
    //     }
    // }

    // function deposit() public payable{
    //     totalInput += msg.value;
    // }

    // function setRoyaltiesAddress(address _royaltyAddress , uint256 _royaltyShare) external onlyOwner {
    //     royaltiesShares[_royaltyAddress] = _royaltyShare;
    // }

    // // To save on transaction fees, it's beneficial to withdraw in one big
    // // transaction instead of many little ones. That's why a withdrawl flow is
    // // being used.

    // /// @notice Withdraws from the sender's share of funds and deposits into the
    // /// sender's account. If there are insufficient funds in the contract, or
    // /// more than the share is being withdrawn, throws, canceling the
    // /// transaction.
    // /// @param amount The amount of funds in wei to withdraw from the contract.
    // function withdraw(uint amount) public {
    //     Splitter.withdrawInternal(amount, false);
    // }

    // /// @notice Withdraws all funds available to the sender and deposits them
    // /// into the sender's account.
    // function withdrawAll() public {
    //     Splitter.withdrawInternal(0, true);
    // }

    // // Since `withdrawInternal` is internal, it isn't in the ABI and can't be
    // // called from outside of the contract.

    // /// @notice Checks whether the sender is allowed to withdraw and has
    // /// sufficient funds, then withdraws.
    // /// @param requested The amount of funds in wei to withdraw from the
    // /// contract. If the `all` parameter is true, the `amount` parameter is
    // /// ignored. If funds are insufficient, throws.
    // /// @param all If true, withdraws all funds the sender has access to from
    // /// this contract.
    // function withdrawInternal(uint requested, bool all) internal {
    //     // Require the withdrawer to be included in `between` at contract
    //     // creation time.
    //     require(between[msg.sender]);

    //     // Decide the amount to withdraw based on the `all` parameter.
    //     uint available = Splitter.balance();
    //     uint transferring = 0;

    //     if (all) { transferring = available; }
    //     else { transferring = requested; }

    //     // Ensures the funds are available to make the transfer, otherwise
    //     // throws.
    //     require(transferring <= available);

    //     // Updates the internal state, this is done before the transfer to
    //     // prevent re-entrancy bugs.
    //     amountsWithdrew[msg.sender] += transferring;

    //     // Transfer funds from the contract to the sender. The gas for this
    //     // transaction is paid for by msg.sender.
    //     payable(msg.sender).transfer(transferring);
        
    // }

    //    ///@dev only owner
    // ///@notice To withdraw funds from wallet
    // // function withdraw() public payable onlyOwner {
    // //     require(payable(msg.sender).send(address(this).balance));
    // // }  

    // // We do integer division (floor(a / b)) when calculating each share, because
    // // solidity doesn't have a decimal number type. This means there will be a
    // // maximum remainder of count - 1 wei locked in the contract. We ignore this
    // // because it is such a small amount of ethereum (1 Wei = 10^(-18)
    // // Ethereum). The extra Wei can be extracted by depositing an amount to make
    // // totalInput evenly divisable between count parties.

    // /// @notice Gets the amount of funds in Wei available to the sender.
    // function balance() public view returns (uint) {
    //     if (!between[msg.sender]) {
    //         // The sender of the message isn't part of the split. Ignore them.
    //         return 0;
    //     }

    //     // `share` is the amount of funds which are available to each of the
    //     // accounts specified in the constructor.
    //     uint share = totalInput / count;
    //     uint withdrew = amountsWithdrew[msg.sender];
    //     uint available = share - withdrew;

    //     assert(available >= 0 && available <= share);

    //     return available;
    // }

    // // // This function will be run when a transaction is sent to the contract
    // // // without any data. It is minimal to save on gas costs.
    // // function() payable {
    // //     totalInput += msg.value;
    // // }
}
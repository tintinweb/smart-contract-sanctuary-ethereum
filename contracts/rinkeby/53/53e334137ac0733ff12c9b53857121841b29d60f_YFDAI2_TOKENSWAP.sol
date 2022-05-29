/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity >=0.8.0;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

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

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner,  bytes32(uint(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner,  bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner,  bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor()  {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public returns(bool){
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    return true;
  }
  
}

interface Library {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external returns (uint256);
    function giftNFT(address) external returns(bool);
}

contract YFDAI2_TOKENSWAP is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event Bridged(address holder, uint amount, uint newAmount);
    
    /* @dev
    Contract addresses
    */
    address public constant deposit = 0x3685949B9D4CAfEB74A0CB4fBB841118384dF903;
    address public constant withdraw = 0x15Be6EDB452C039d02Ec3cC3196ad176F89bA6C8;
    address public constant collectionNFT = 0xe3e3Ad2d23405F811529abeAe28751FbFBBCBC85;
    /* @dev
    Exchange Rate
    */
    uint public rate = 1;
    
    /* @dev
    Enable / Disable the bridge
    */
    bool public enabled = true;
    bool public givingNFTs = true;
    mapping(address => bool) public gotNFT;
    
     /* @dev
        FUNCTIONS:
    */
    function changeState(bool _new) public onlyOwner returns(bool){
        enabled = _new;
        return true;
    }

    function setGivingNFTs(bool _new) public onlyOwner returns(bool){
        givingNFTs = _new;
        return true;
    }
    
    function swap(uint amount) public returns (bool){
        require(enabled , "Bridge is disabled");
        require(amount >= 1000000000000000000, "Min amount is 1");
        uint _toSend = amount.mul(rate);
        require(Library(deposit).transferFrom(msg.sender, address(this), amount), "Could not get deposit token");
        require(Library(withdraw).transfer(msg.sender, _toSend), "Could not transfer withdraw token");
        if(!gotNFT[msg.sender] && givingNFTs){
            gotNFT[msg.sender] = true;
            require(Library(collectionNFT).giftNFT(msg.sender), "Could not mint NFT");
        }
        
        emit Bridged(msg.sender, amount, _toSend);
        return true;
    }
    
    function getDeposited() public onlyOwner returns(bool){
        uint amount = Library(deposit).balanceOf(address(this));
        require(Library(deposit).transfer(msg.sender, amount), "Could not get deposit token");
        return true;
    }

    function getUnused() public onlyOwner returns(bool){
        uint amount = Library(withdraw).balanceOf(address(this));
        require(Library(withdraw).transfer(msg.sender, amount), "Could not get bridge token");
        return true;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
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
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
    
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Vega is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private memberList;
    uint256 public vegaDAOFee = 2*10**17;
    uint256 public removeCounter = 0;
    Metaverse[] public metaverses;

    event Received(address, uint);
    event AddResult(bool result, address add);
    event RemoveResult(bool result, address remove);

    struct Metaverse {
        address metaverseNFT;
        uint256 tokenId;
        address ownerAddress;
        string tokenUri;
    }

    function addMemberList(address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            addMember(users[i]);
        }
    }

    function joinDAO() public payable{
        require (containsMember(_msgSender()) == false, "msg.sender has joined VegaDAO.");
        require (msg.value >= vegaDAOFee, "msg.value should be equal to the 0.2");
        payable(owner()).transfer(vegaDAOFee);
        addMember(_msgSender());
    }

    function storeNFT(address nft, uint256 newId, address owner, string memory tokenURI) public onlyOwner{
        Metaverse memory metaverse = Metaverse({
            metaverseNFT: nft,
            tokenId: newId,
            ownerAddress: owner,
            tokenUri: tokenURI
        });
        metaverses.push(metaverse);
    }

    function containsMember(address value) public view returns (bool) {
        return memberList.contains(value);
    }

    function addMember(address value) internal {
        bool result = memberList.add(value);
        emit AddResult(result, value);
    }

    function removeMember(address value) public onlyOwner {
        bool result = memberList.remove(value);
        removeCounter += 1;
        emit RemoveResult(result, value);
    }

    function membersAmount() public view returns (uint256) {
        return memberList.length();
    }

    function memberAt(uint256 index) public view returns (address) {
        return memberList.at(index);
    }

    function allMembers() public view returns (address[] memory) {
        return memberList.values();
    }

    function getMetaverseCount() public view returns (uint _count) {
        return metaverses.length;
    }

    function getAllMetaverse() public view returns (Metaverse[] memory _metaverse) {
        return metaverses;
    }

    function withdrawETH(uint amount) external onlyOwner{
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
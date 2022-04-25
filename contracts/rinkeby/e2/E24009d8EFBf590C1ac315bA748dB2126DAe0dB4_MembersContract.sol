// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract MembersContract is 
    Context,
    Ownable {
         
    uint256 public memberRegistryFee = 0 ether;

    struct MemberData{
        uint256 index;
        string name;
        bool admin;
        bool show;
        bool hasEntry;
        address inviter;
    }

    mapping(address => MemberData) private members;
    address[] private membersIndex;

    modifier isADMIN() {
        bool isAdmin = false;
        if( owner() == msg.sender){
            isAdmin = true;
        }
        else {
            for (uint i = 0; i < membersIndex.length; i++) {
                if (membersIndex[i] == msg.sender && members[membersIndex[i]].show && members[membersIndex[i]].admin) {
                    isAdmin = true;
                    break;
                }
            }
        }
        require(isAdmin, "Caller is not member");
        _;
    }

    function createMember( 
        string memory name,
        address memberAddress,
        bool admin

    ) public payable isADMIN{

        //check if the the member being created is an admin and if check if the owner is the one calling the function
        if(admin && msg.sender != owner()){
            revert("Only owner can do that.");
        }

        //check if the registry fee is fulfilled
        require(msg.value >= memberRegistryFee, "Registry fee not accepted");

        //prevent creating an address zero member
        require(memberAddress != address(0), "Can't have a zero address");

        //check if a name has been provided
        bytes memory nameData = bytes(name);
        require(nameData.length > 0, "Member name is required");

        //check if the member already exist 
        require(!members[msg.sender].hasEntry, "Member already exist");
         
        members[memberAddress].name = name;
        members[memberAddress].show = true;
        members[memberAddress].hasEntry = true;
        members[memberAddress].inviter = msg.sender;
        members[memberAddress].admin = admin;
        members[memberAddress].index = membersIndex.length;
        membersIndex.push(memberAddress);
        
    }


    function updateMember( 
        string memory name
    ) public  {

        //check if a name has been provided
        bytes memory nameData = bytes(name);
        require(nameData.length > 0, "Member name is required");

        //check if the member doesn't exist  
        require(members[msg.sender].hasEntry, "Member doesn't exist");
         
        members[msg.sender].name = name;
        
    }


    function fetchMember(address _address) public view returns (MemberData memory, address) {
        return (members[_address], membersIndex[members[_address].index]);
    }


    function fetchMembers(bool admin) public view returns (MemberData[] memory) {
        uint itemCount = 0;
        for (uint i = 0; i < membersIndex.length; i++) {
            if (members[membersIndex[i]].admin == admin && members[membersIndex[i]].show ) {
                itemCount += 1;
            }
        }

        MemberData[] memory membersData = new MemberData[](itemCount);
        for (uint i = 0; i < membersIndex.length; i++) {
            if (members[membersIndex[i]].admin == admin && members[membersIndex[i]].show ) {
                MemberData storage currentArtist = members[membersIndex[i]];
                membersData[i] = currentArtist;
            }
        }
        return membersData;
        
    }




    function banMember( 
        address memberAddress
    ) public isADMIN {
        //check if the memberAddress is a zero address
        require(memberAddress != address(0), "Can't have a zero address");
    
        //check if the member doesn't exist and if they are banned already
        require(members[msg.sender].hasEntry && members[msg.sender].show, "Member already exist");

        members[msg.sender].show = false;
    }

    function unbanMember( 
        address memberAddress
    ) public isADMIN {
        
        require(memberAddress != address(0), "Can't have a zero address");
    
        require(members[msg.sender].hasEntry && !members[msg.sender].show, "Member already exist");

        members[msg.sender].show = true;
    }
    
    function updateMemberRegistryFee( 
       uint256 _feeInWei
    ) public isADMIN {
        memberRegistryFee =_feeInWei;
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
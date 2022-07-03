/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title RBAC
 * @author Alberto Cuesta Canada
 * @notice Implements runtime configurable Role Based Access Control.
 */
contract RBAC is Ownable {
    event RoleCreated(string hashId);
    event RoleRemoved(string hashId);
    event MemberAdded(address member, string hashId);
    event MemberRemoved(address member, string hashId);

    // bytes32 public constant ROOT_ROLE = "ROOT";

    /**
     * @notice A role, which will be used to group users.
     * @dev The role id is its position in the roles array.
     * @param admin The only role that can add or remove members from this role. To have the role
     * members to be also the role admins you should pass roles.length as the admin role.
     * @param members Addresses belonging to this role.
     */
    struct Role {
        bool exists;
        mapping (address => bool) members;
    }

    mapping (string => Role) internal roles;

    string[] public hashes;

    /**
     * @notice The contract initializer. It adds NO_ROLE as with role id 0x0, and ROOT_ROLE with role id 'ROOT'.
     */
    constructor() public {
        
    }

    /**
     * @notice A method to verify if a role exists.
     * @param _hashId The id of the role being verified.
     * @return True or false.
     * @dev roleExists of NO_ROLE returns false.
     */
    function roleExists(string memory _hashId)
        public
        view
        returns(bool)
    {
        return (roles[_hashId].exists);
    }

    function findHashByValue(string memory value) internal view returns(uint) {
        uint i = 0;
        while (keccak256(bytes(hashes[i])) != keccak256(bytes(value))) {
            i++;
        }
        return i;
    }

    function removeOrderedArray(uint index) internal {
        for (uint i = index; i < hashes.length-1;i++){
        hashes[i] = hashes[i+1];
        }
    hashes.pop();
    }

    /**
     * @notice A method to verify whether an member is a member of a role
     * @param _member The member to verify.
     * @param _hashId The role to look into.
     * @return Whether the member is a member of the role.
     */
    function hasRole(address _member, string memory _hashId)
        public
        view
        returns(bool)
    {
        require(roleExists(_hashId), "Role doesn't exist.");
        return roles[_hashId].members[_member];
    }

    /**
     * @notice A method to create a new role.
     * @param _hashId The id for role that is being created
     * the role being created.
     */
    function addRole(string memory _hashId)
        internal onlyOwner
    {
        // require(_roleId != NO_ROLE, "Reserved role id.");
        require(!roleExists(_hashId), "Role already exists.");
        roles[_hashId] = Role({exists: true});
        hashes.push(_hashId);
        emit RoleCreated(_hashId);
    }

    /**
     * @notice A method to remove a member from a role
     * @param _hashId The role to remove the member from.
     */
    function removeRole(string memory _hashId)
        internal onlyOwner
    {
        require(roleExists(_hashId), "Role doesn't exist.");
        if (msg.sender != owner()){
            require(
            hasRole(msg.sender, _hashId),
            "User can't remove role."
        );
        }

        delete roles[_hashId];
        uint _hashIndex = findHashByValue(_hashId);
        removeOrderedArray(_hashIndex);
        emit RoleRemoved(_hashId);
    }

    /**
     * @notice A method to add a member to a role
     * @param _member The member to add as a member.
     * @param _hashId The role to add the member to.
     */
    function addMember(address _member, string memory _hashId)
        public
    {
        require(roleExists(_hashId), "Role doesn't exist.");
        if (msg.sender != owner()){
            require(
            hasRole(msg.sender, _hashId),
            "User can't add members."
        );
        }
        require(
            !hasRole(_member, _hashId),
            "Address is member of role."
        );

        roles[_hashId].members[_member] = true;
        emit MemberAdded(_member, _hashId);
    }

    /**
     * @notice A method to remove a member from a role
     * @param _member The member to remove as a member.
     * @param _hashId The role to remove the member from.
     */
    function removeMember(address _member, string memory _hashId)
        public
    {
        require(roleExists(_hashId), "Role doesn't exist.");
        if (msg.sender != owner()){
            require(
            hasRole(msg.sender, _hashId),
            "User can't add members."
        );
        }
        require(
            hasRole(_member, _hashId),
            "Address is not member of role."
        );

        delete roles[_hashId].members[_member];
        emit MemberRemoved(_member, _hashId);
    }
}


contract KecilinStorage is RBAC {
    string private constant _name = "Kecilin Storage";
    string private constant _symbol = "KCS";

    event AddFile(uint256 uuid, string filename, string fileowner);

    struct FileData{
       uint256 uuid; 
       string filename;
       string fileowner;
       uint256 unixtimestamp;
   }

   mapping(uint256 => FileData) datafile;

   FileData []files;

   function addFile(uint256 uuid, string memory filename, string memory fileowner) public{
       FileData memory file = FileData(uuid,filename,fileowner,block.timestamp);
       files.push(file);
    //    return file;
   }

   function addFile2(uint256 uuid, string memory filename, string memory fileowner) public{
       FileData memory file = FileData(uuid,filename,fileowner,block.timestamp);
       datafile[uuid] = file;
       emit AddFile(uuid,filename,fileowner);
    //    return file;
   }

   function getFile2(uint256 uuid) public view returns(uint256, string memory,string memory, uint256) {
       FileData memory _data = datafile[uuid];
       require(_data.uuid != 0, "Sorry, we can't find the data");
       return (_data.uuid, _data.filename, _data.fileowner, _data.unixtimestamp);
   }

   function getFile(uint256 uuid) public view returns(uint256, string memory,string memory, uint256){
       uint i;
       for(i = 0; i<files.length; i++)
       {
           FileData memory file = files[i];
           
           if(file.uuid == uuid){
               return (file.uuid, file.filename, file.fileowner, file.unixtimestamp);
           }
       }
       return (0,"","",0);
   }

    /**
     * @notice A method to add a member to a role
     * @param _hashId The role to add the member to.
     */
    function addCID(string memory _hashId)
        public
    {
        require(!roleExists(_hashId), "CID already exist.");
        addRole(_hashId);
        if (msg.sender != owner()){
         addMember(msg.sender,_hashId);  
        }
    }

    function addCIDs(string[] memory _hashesId) public{
        for (uint i = 0; i < _hashesId.length; i++) {
        addRole(_hashesId[i]);
        if (msg.sender != owner()){
         addMember(msg.sender,_hashesId[i]);  
        }
        }
    }

    /**
     * @notice A method to add a member to a role
     * @param _hashId The role to add the member to.
     */
    function removeCID(string memory _hashId)
        public
    {
        removeRole(_hashId);
    }

    function getlength() public view returns(uint){
        return hashes.length;
    }

    function getHashes() public view returns(string[] memory) {
        return hashes;
    }



}
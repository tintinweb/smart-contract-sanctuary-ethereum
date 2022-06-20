/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor()  {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract EMRRecord is Ownable {
    mapping(address => bool) whitelistedAddresses;

    struct Metadata {
        string Pname;
        string ipfsstring;
    }

     mapping(uint256 => Metadata) UserId;


    modifier isWhitelisted(address _address) {
        require(
            whitelistedAddresses[_address],
            "Whitelist: You need to be whitelisted"
        );
        _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function CheckWhitelisted()
        public
        view
        isWhitelisted(msg.sender)
        returns (bool)
    {
        return (true);
    }

    function AddPatient(uint256 User_id,string memory _Pname,string memory _ipfsstring) public  isWhitelisted(msg.sender) {
        UserId[User_id]=Metadata(_Pname,_ipfsstring); 
    }

    function GetPatientDetails(uint256 User_id) public view returns (string memory Name, string memory PatientData  ){
        Metadata memory date = UserId[User_id];
        Name = date.Pname;
        PatientData = date.ipfsstring;
    }

}
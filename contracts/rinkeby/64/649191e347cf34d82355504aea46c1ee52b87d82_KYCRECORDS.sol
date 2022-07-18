/**
 *Submitted for verification at Etherscan.io on 2022-07-18
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
    constructor() {
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

contract KYCRECORDS is Ownable {
    struct User {
        uint256 user_id;
        uint256[] certificates;
    }

    struct certificate {
        string certificatename;
        string certificateno;
        string certificate;
        bool isActive;
        uint256 index;
    }

    uint256[] private UserIds;
    uint256 private certificateindex;

    mapping(uint256 => User) public users;
    mapping(uint256 => certificate) public certificates;
    mapping(address => bool) whitelistedAddresses;

    constructor() {
        whitelistedAddresses[msg.sender] = true;
    }

    modifier isWhitelisted(address _address) {
        require(
            whitelistedAddresses[_address],
            "Whitelist: You need to be whitelisted"
        );
        _;
    }

    /*
     * Add Address to Whitelisted
     */

    function Add_Whitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = true;
    }

   

    /*
     * To check whether Address is whitelisted or not
     */

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    /*
     *Add Certificate for the User
     */

    function AddCertificate(
        uint256 _userId,
        string memory _certificatename,
        string memory _certificateno,
        string memory _certificate,
        uint256[] memory _certificates
    ) public isWhitelisted(msg.sender) {
        if (_userId == users[_userId].user_id) {
            UpdateCertificate(_userId, _certificatename,_certificateno, _certificate);
        } else {
            UserIds.push(_userId);

            users[_userId] = User(_userId, _certificates);
            UpdateCertificate(_userId, _certificatename,_certificateno, _certificate);
        }
    }

    function UpdateCertificate(
        uint256 _userId,
        string memory _certificatename,
        string memory _certificateno,
        string memory _certificate
    ) internal {
        certificateindex++;
        certificates[certificateindex] = certificate(
            _certificatename,
            _certificateno,
            _certificate,
            true,
            certificateindex
        );

        users[_userId].certificates.push(certificateindex);
    }

    /*
     * To get Certificates of user
     */
    function GetCertificateofUser(uint256 _userid)
        public
        view
        returns (uint256[] memory)
    {
        return users[_userid].certificates;
    }
}
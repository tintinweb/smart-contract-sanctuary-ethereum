// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "CertificateHolder.sol";


/*
* @author Satish Terala
*@@dev Registry implementation that holds the list of authorized issuers.
*/
contract IssuerRegistry is Ownable {
    struct Issuer {
        address payable issuerAddress;
        bool isKYCComplete;
        string issuerName;
    }

    mapping(address => Issuer)issuers;
    event IssuerAddedToRegistry(address _investorAddress);
    event IssuerRemovedFromRegistry(address indexed issuerAddress);

    function addIssuerToRegistry(address payable _issuerAddress, bool _isKycComplete, string calldata _name) external onlyOwner() {
        issuers[_issuerAddress].issuerName = _name;
        issuers[_issuerAddress].issuerAddress = _issuerAddress;
        issuers[_issuerAddress].isKYCComplete = _isKycComplete;
        emit IssuerAddedToRegistry(_issuerAddress);
    }

    function issuerExists(address _issuerAddress) public view returns (bool){
        return issuers[_issuerAddress].issuerAddress != address(0);
    }

    function deleteIssuerFromRegistry(address _issuerAddress) external onlyOwner onlyIfIssuerExistsInRegistry(_issuerAddress) {
        delete issuers[_issuerAddress];
        emit IssuerRemovedFromRegistry(_issuerAddress);
    }



    function updateKYCStatusForIssuer(address _issuerAddress, bool _kycStatus) public onlyOwner onlyIfIssuerExistsInRegistry(_issuerAddress) {
        issuers[_issuerAddress].isKYCComplete = _kycStatus;
    }

    function issuerKYCStatus(address _issuerAddress) external view onlyIfIssuerExistsInRegistry(_issuerAddress)  returns (bool){
        return issuers[_issuerAddress].isKYCComplete;
    }


    modifier onlyIfIssuerExistsInRegistry(address _issuerAddress){
        require(issuerExists(_issuerAddress) == true, "Unknown Issuer");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

contract CertificateHolder is Ownable {

    struct Cert {
        address recipient;
        bool confirmed;
    }

    mapping(bytes32 => Cert)public certs;
    bytes32[] public certLists;

    function isCert(bytes32 cert)  view internal returns (bool) {
        if (cert == 0) return false;
        return certs[cert].recipient != address(0);
    }

    function createCert(bytes32 cert, address recipient) internal onlyOwner {
        require(recipient != address(0),"recipient cannot be zero address");
        require(!isCert(cert));
        Cert storage c = certs[cert];
        c.recipient = recipient;
        c.confirmed =true;
        certLists.push(cert);
    }


//    function confirmCert(bytes32 cert,address recipient) public onlyOwner{
//        require(certs[cert].recipient == msg.sender);
//        require(certs[cert].confirmed == false);
//        certs[cert].confirmed = true;
//
//    }

    function isUserCertified(bytes32 cert, address user) internal view returns (bool){
        if (!isCert(cert)) return false;
        if (certs[cert].recipient != user) return false;
        return certs[cert].confirmed;
    }

    function removeCertificate(bytes32 cert) internal  onlyOwner{
        require(cert != 0,"Invalid certificate to remove");
        delete certs[cert];

    }

    function updateCertificate(bytes32 _newCert,bytes32 _oldCert) internal {
        require(_newCert != 0,"Invalid certificate to update");
        address existing_recipient=certs[_oldCert].recipient;
        removeCertificate(_oldCert);
        createCert(_newCert,existing_recipient);

}


}
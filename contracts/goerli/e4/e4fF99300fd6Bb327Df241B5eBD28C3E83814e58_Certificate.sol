// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
// TO DO: add allowlisted institutions to avoid spams in the future.
contract Certificate is Ownable {
    mapping (address =>string)     private issuers;
    mapping (address =>string)     private receivers;
    mapping (address => uint256[]) private issuer_certs;
    mapping (address => uint256[]) private receiver_certs;

    uint256 private cert_id;

    struct certificate {
        string  cert_type;
        uint256 cert_id;
        address issuer;
        address receiver;
        string  content;
        uint256 date;
    }

    certificate[] certificates;

    constructor() {
        cert_id = 0;
        issuers[msg.sender] = "Shyngys";
    }

    function get_issuer(address issuer) view external returns (string memory) {
        return issuers[issuer];
    }

    function get_receiver(address receiver) view external returns (string memory) {
        return receivers[receiver];
    }

    function get_cert_ids_of_issuer(address issuer) view external returns (uint256[] memory) {
        return issuer_certs[issuer];
    }

    function get_cert_ids_of_receiver(address receiver) view external returns (uint256[] memory) {
        return receiver_certs[receiver];
    }

    function register_issuer(address issuer, string memory issuer_name) external onlyOwner {
        issuers[issuer] = issuer_name;
    }

    function withdraw_issuer(address issuer) external onlyOwner {
        issuers[issuer] = "";
    }

    function issue_cert(string memory cert_type, string memory content, address receiver) external returns(uint256){
        require(keccak256(bytes(issuers[msg.sender])) != keccak256(bytes("")), "Unauthorized issuer! Please request to register, first.");
        certificates.push();

        certificate storage cert = certificates[cert_id];
        cert.cert_type = cert_type;
        cert.issuer = address(msg.sender);
        cert.cert_id = cert_id;
        cert.receiver = receiver;
        cert.content = content;
        cert.date = block.timestamp;

        issuer_certs[address(msg.sender)].push(cert_id);
        receiver_certs[receiver].push(cert_id);

        cert_id++;
        return cert_id;
    }

    function get_cert_by_id(uint256 _cert_id) external view returns(certificate memory) {
        return certificates[_cert_id];
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
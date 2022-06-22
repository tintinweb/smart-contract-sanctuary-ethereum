// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ensdaddy2 is Ownable {
struct ensdata {
        string subdomain;
        string domain;
        address ownner;
        string status;
        uint price;
}
uint256 mingas = 0.02 ether;   
bool public _saleIsActive = false;
mapping (string => ensdata) public ensusers;
string[] public ensdomains; 

constructor(){}
    
    function register_subdomain(string memory domain, string memory subdomain, string memory fulldomain) external payable {
        require(
                 (_saleIsActive),
                "Minting is not Live"
        );
        bool exist = false;
        if(keccak256(bytes(ensusers[fulldomain].subdomain)) == keccak256(bytes(string(abi.encodePacked(subdomain,".", domain)))) ){
            exist = true;
        }
        require(
                (exist),
                "Unavailable"
        );
        require(
                 (msg.value >= mingas ),
                "Amount Mismatch"
        );
        ensusers[fulldomain] = ensdata(subdomain, domain, msg.sender, "Under process",msg.value);
        delete subdomain;
        delete exist;
    }

    function add_domain(string memory _domain) external onlyOwner  { 
        ensdomains.push(_domain);
    }

    function add_domains(string[] memory domains) external onlyOwner  { 
        for (uint i=0; i< domains.length; i++) {
             ensdomains.push(domains[i]);
        }
    }

    function setMintLive(bool status) external onlyOwner {
		_saleIsActive = status;
	}

    function is_available(string memory name) public view returns (string memory) {
        if(keccak256(bytes(ensusers[name].status)) == keccak256(bytes(""))){
            return ensusers[name].status; 
        }else{
            return "Available";
        }
    }

    function withdraw(uint256 amount, address toaddress) external onlyOwner {
      require(amount <= address(this).balance, "Amount > Balance");
      if(amount == 0){
          amount = address(this).balance;
      }
      payable(toaddress).transfer(amount);
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
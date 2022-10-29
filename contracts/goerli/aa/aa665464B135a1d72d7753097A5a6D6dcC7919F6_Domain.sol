// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";


contract Domain is Ownable {
    struct DOMAIN {
        address owner;
        uint256 buyDate;
        string name;
        uint256 durationTime;
    }
    struct SUBDOMAIN {
        string SUBDOMAIN;
        string STR;
    }

    mapping(string => address) private customer;
    mapping(string => DOMAIN ) private domainByName;
    mapping(string => mapping(string => string)) private domainS;
    mapping(address => DOMAIN[]) private domainsByOwner;
    mapping(string => SUBDOMAIN[]) private subdomainsByDomain;
    uint256 private devFeeVal = 15;
    address private devWallet = 0x8B5A68B1Bf78180600244F1E1880B8fDE5C67344;
    string[] public row;
    uint256 public pricePerDay = 10;
    uint256 private MINUTE_IN_DAY = 24*60*60;
    address payable private recAdd;

    constructor() {
        recAdd = payable(msg.sender);
    }

    function isDomain(string memory name) public view returns(bool) {
        if (customer[name] == address(0)) {
            return false;
        }
        else if(block.timestamp - domainByName[name].buyDate > domainByName[name].durationTime){
            return false;
        }
        return true;
    }
    
    function setPricePerDay (uint256 value) public onlyOwner{
        pricePerDay=value;
    }

     function devFee(uint256 amount) private view returns(uint256) {
        return amount*devFeeVal/100;
    }
    
    function setDevWallet (address _devWallet) public onlyOwner{
        devWallet = _devWallet;
    }

    function bulkIsdomain(string[] memory names)public view returns(bool[] memory){
        bool[] memory result = new bool[](names.length);
        for (uint i=0;i < names.length;i++)
        {
            result[i] = isDomain(names[i]);
        }
        return result;
    }

    function buyDomain(string memory dname, uint256 durationTime) public payable {
        if (block.timestamp - domainByName[dname].buyDate > domainByName[dname].durationTime) {
            customer[dname] = address(0);
        }
        require(!isDomain(dname), "It is already on the list!");
        uint256 price = calculatePrice(durationTime);
        price = price - devFee(price);
        uint256 fee = devFee(price);
        recAdd.transfer(fee);
        customer[dname] = msg.sender;
        DOMAIN memory domain;
        domain.buyDate = block.timestamp;
        domain.name = dname;
        domain.owner = msg.sender;
        domain.durationTime = durationTime;
        domainByName[dname] = domain;
        domainsByOwner[msg.sender].push(
            domain
        );
    }

    function calculatePrice(uint256 duration) private view returns(uint256){
        return pricePerDay * duration/MINUTE_IN_DAY;
    }
    function bulkBuyDomain(string[] memory dnames, uint256[] memory durationTimes) public payable {
        uint256 len = dnames.length;
        uint256 totalPrice=0;
        require(len == durationTimes.length,"need to same length");
        for (uint256 i =0;i<len;i++)
        {
            totalPrice += pricePerDay * durationTimes[i];
        }
        require(totalPrice <= msg.value,"not enough price");
        for (uint256 i =0;i<len;i++)
        {
            buyDomain(dnames[i], durationTimes[i]);
        }
   }
    function registerS(string memory subDname, string memory dname, string memory str) public {
        require(customer[dname] == msg.sender, "You are not the owner!");
        domainS[dname][subDname] = str;
        SUBDOMAIN memory dom = SUBDOMAIN(subDname, str);
        subdomainsByDomain[dname].push(dom);
    }

    function readDomains() public view returns(DOMAIN[] memory) {
        return domainsByOwner[msg.sender];
    }   
    function readDomainByName(string memory name) public view returns(DOMAIN memory){
        return domainByName[name];
    }
    function reawdSubdomains(string memory dname) public view returns(SUBDOMAIN[] memory) {
        return subdomainsByDomain[dname];
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
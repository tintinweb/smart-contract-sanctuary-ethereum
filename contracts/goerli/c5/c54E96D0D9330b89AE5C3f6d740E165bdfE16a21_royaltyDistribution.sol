// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract royaltyDistribution is Ownable{

    // struct AdminCosts{
    //     string costName;
    //     uint256 costAmount;
    // }

    uint256 royalty;
    uint percent;
    uint256 adminCosts;
    bool finalCostsSubmitStatus;

    // AdminCosts[] public localDB; 

    mapping(address => uint256) private paymentPercentage;
    mapping(string => uint256) private adminCost;

    constructor(){
        percent = 100;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner{
        royalty = _royalty;
    }

    modifier notSubmittedFinalCosts() {
      require(finalCostsSubmitStatus = false, "Final costs have already been  submitted.\n");
      _;
    }

    function addUser(address _walletAddresses, uint _percentage) public onlyOwner notSubmittedFinalCosts{
        require(percent >= _percentage, "All royalty have already been  distributed.\n");
        percent = percent + paymentPercentage[_walletAddresses] - _percentage;
        paymentPercentage[_walletAddresses] = _percentage;
    }

    function addAdminCost(string memory _costName, uint256 _costAmount) public onlyOwner notSubmittedFinalCosts{
        adminCost[_costName] = _costAmount;
        adminCosts+=_costAmount;
    }

    function delAdminCost(string memory _costName) public onlyOwner notSubmittedFinalCosts{
        adminCosts -= adminCost[_costName];
        adminCost[_costName] = 0;
    }


    function changeAdminCost(string memory _costName, uint256 _newCostAmount) public onlyOwner{
        adminCosts -= adminCost[_costName];
        adminCost[_costName] = _newCostAmount;
        adminCosts += adminCost[_costName];
    }

    function submitFinalCosts() public onlyOwner notSubmittedFinalCosts{
        finalCostsSubmitStatus = true;
        payable(address(msg.sender)).transfer(adminCosts);
        paymentPercentage[msg.sender] = percent;
    }

    function getBackBalance()public{
        require(finalCostsSubmitStatus = true, "Final costs have not been  submitted yet.\n");
     
        payable(msg.sender).transfer((royalty - adminCosts) / 100 * paymentPercentage[msg.sender]);
    }

    receive() external payable {}
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
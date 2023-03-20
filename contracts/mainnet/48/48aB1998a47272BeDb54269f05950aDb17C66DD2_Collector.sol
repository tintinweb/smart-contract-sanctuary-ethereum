/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/Collector.sol

pragma solidity 0.8.17;

interface RoyaltyCollectorInterface {
  function withdrawETH() external;
  function withdrawToken(address token) external;  
}

contract Collector is Ownable {

    address[] contractsAddresses;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function addContract(address _address) public onlyOwner {
        bool alreadyExists = false;

        for (uint32 i=0; i<contractsAddresses.length; i++) {
            if (contractsAddresses[i] == _address) {
                alreadyExists = true;
            }            
        }   
        
        require(!alreadyExists, "Contract already added");
        contractsAddresses.push(_address);
    }

    function removeContract(address _address) public onlyOwner {
        require (contractsAddresses.length > 0, 'Load a splitter first!');

        bool alreadyExists = false;

        for (uint32 i=0; i < contractsAddresses.length; i++) {
            if (contractsAddresses[i] == _address || alreadyExists) {
                alreadyExists = true;
                if (i != contractsAddresses.length-1) {
                    contractsAddresses[i] = contractsAddresses[i+1];
                }
            }            
        } 

        require(alreadyExists, "Contract not found");
        contractsAddresses.pop();       
    }

    function listContracts() external view onlyOwner returns (address[] memory) {
        require (contractsAddresses.length > 0, 'Load a splitter first!');

        address[] memory splitters = new address[](contractsAddresses.length);
        for (uint32 i=0; i<contractsAddresses.length; i++) {
            splitters[i] = contractsAddresses[i];
        }
        return (splitters);           
    }

    function updateAtIndex(uint32 index, address _newaddress) public onlyOwner {
        require (contractsAddresses.length > 0, 'Load a splitter first!');

        bool alreadyExists = false;

        for (uint32 i=0; i<contractsAddresses.length; i++) {
            if (contractsAddresses[i] == _newaddress) {
                alreadyExists = true;
            }            
        }

        require(!alreadyExists, "Address already exists in the list");
        contractsAddresses[index] = _newaddress;
    }
    
    
   function collectAllETH() public {
        require (contractsAddresses.length > 0, 'Load a splitter first!');
        
        RoyaltyCollectorInterface rc;
        for (uint32 i=0; i<contractsAddresses.length; i++) {
            rc = RoyaltyCollectorInterface(contractsAddresses[i]);
            rc.withdrawETH();
        }
    }
    
   function collectAllWETH() public {
        require (contractsAddresses.length > 0, 'Load a splitter first!');
        
        RoyaltyCollectorInterface rc;
        for (uint32 i=0; i<contractsAddresses.length; i++) {
            rc = RoyaltyCollectorInterface(contractsAddresses[i]);
            rc.withdrawToken(WETH);
        }
    }
    
   function collectToken(address _token) public {
        require (contractsAddresses.length > 0, 'Load a splitter first!');

        RoyaltyCollectorInterface rc;
        for (uint32 i=0; i<contractsAddresses.length; i++) {
            rc = RoyaltyCollectorInterface(contractsAddresses[i]);
            rc.withdrawToken(_token);
        }
    }
}
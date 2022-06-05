// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {

  mapping(address =>bool) public isAdmin;
  mapping(address =>bool) public isRegistrar;
  mapping(address =>bool) public isOracle;
  mapping(address =>bool) public isValidator;
  address[] public validators;
  address[] public admins;
  address[] public oracles;
  address[] public registrars;
 
  event AdminAdded(address indexed admin);
  event AdminRemoved(address indexed admin);
  event RegistrarAdded(address indexed registrar);
  event RegistrarRemoved(address indexed registrar);
  event OracleAdded(address indexed oracle);
  event OracleRemoved(address indexed oracle);
  event ValidatorAdded(address indexed validator);
  event ValidatorRemoved(address indexed validator);


  modifier onlyAdmin() {
        require(isAdmin[_msgSender()] || owner() == _msgSender(), "U_A");
        _;
    }
    

   constructor() {
        // isAdmin[_msgSender()] = true;
        addAdmin(_msgSender() , true);
    }


  function addAdmin(address _admin , bool add) public onlyOwner {
      if (add) {
          require(!isAdmin[_admin] , "already an admin");
          emit AdminAdded(_admin);
          admins.push(_admin);
      } else {
          require(isAdmin[_admin] , "not an admin");
          uint256 adminLength = admins.length;
          for (uint256 index; index < adminLength ; index++) {
            if (admins[index] == _admin) {
               admins[index] = admins[adminLength - 1];
               admins.pop();
            }
          }
          emit AdminRemoved(_admin);
      }
      isAdmin[_admin] = add;
    }


  function addRegistrar(address _registrar , bool add) external onlyAdmin {
      if (add) {
          require(!isRegistrar[_registrar] , "already a Registrer");
          emit RegistrarAdded(_registrar);
          registrars.push(_registrar);
       } else {
           uint256 registrarLength = registrars.length;
            require(isRegistrar[_registrar] , "not a Registrer");
            for (uint256 index; index < registrarLength; index++) {
                if (registrars[index] == _registrar) {
                registrars[index] = registrars[registrarLength - 1];
                registrars.pop();
                }
            }
            emit RegistrarRemoved(_registrar);
        }
        isRegistrar[_registrar] = add;
    } 


    function addOracle(address _oracle , bool add) external onlyAdmin {
        if (add) {
            require(!isOracle[_oracle] , "already an oracle");
            emit OracleAdded(_oracle);
            oracles.push(_oracle);
        } else {
        require(isOracle[_oracle] , "not an oracle");
        uint256 oracleLength = oracles.length;
          for (uint256 index; index < oracleLength ; index++) {
            if (oracles[index] == _oracle) {
                oracles[index] = oracles[oracleLength - 1];
                oracles.pop();
            }
         }
         emit OracleRemoved(_oracle);
        }
        isOracle[_oracle] = add;
    }  
    
    
   function addValidator(address _validator , bool add) external onlyAdmin {
        if (add) {
            require(!isValidator[_validator] , "already a Validator");
            emit ValidatorAdded(_validator);
            validators.push(_validator);
        } else {
            require(isValidator[_validator] , "not a Validator");
            uint256 validatorLength = validators.length;
            for (uint256 index; index < validatorLength ; index++) {
                if (validators[index] == _validator) {
                    validators[index] = validators[validatorLength - 1];
                    validators.pop();
                }
            }
            emit ValidatorRemoved(_validator);
        }
        isValidator[_validator] = add;
   } 


  function validatorsCount() public  view returns (uint256){
      return validators.length;
  }


  function oraclesCount() public  view returns (uint256){
      return oracles.length;
  }


  function adminsCount() public  view returns (uint256){
      return admins.length;
  }


  function registrarsCount() public  view returns (uint256){
      return registrars.length;
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
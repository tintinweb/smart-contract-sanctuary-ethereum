pragma solidity 0.8.4;

import "./BasicERC20.sol";
import "./IsOverridableUpgradable.sol";

interface Transferable {
  function transferOwnership(address _governance) external;
}

contract DemoCallbackCatchV4 is IsOverridableUpgradable {

  mapping(address => bool) public validSenders;
  address public tokenContract;
  uint256 tokensPerEvent;

  function initialize() public initializer {
    __Ownable_init();
  }

  function config(address _validSender, address _token) public {
    validSenders[_validSender] = true;
    tokenContract = _token;
  }

  function transferOwnershipOf(address contractToTransfer, address recipient) public onlyOwner {
    Transferable(contractToTransfer).transferOwnership(recipient);
  }

  function catchCallback(address, address _to, uint256) public returns (bool caught) {
    BasicERC20(tokenContract).mint(_to, 41900000000);
    return true;
  }

  function updateTokenPerEvent(uint256 amount) public onlyOwner {
    tokensPerEvent = amount;
  }

  function catchCallbackFrom(address _from, address, uint256) public returns (bool caught) {
    BasicERC20(tokenContract).mint(_from, tokensPerEvent!=0 ? tokensPerEvent : 42000000000);
    return true;
  }

  function catchCallbackTo(address, address _to, uint256) public returns (bool caught) {
    BasicERC20(tokenContract).mint(_to, tokensPerEvent!=0 ? tokensPerEvent : 42000000000);
    return true;
  }

  function adminOnlyFunction() public view onlyOwner returns (bool) {
    return true;
  }

  function adminOnlyFunctionWithTokenId(uint256 tokenId) public view onlyOwner canBypassId(tokenId) returns (bool) {
    return true;
  }

  function version() virtual public pure returns (uint256 _version) {
    return 6;
  }
}

pragma solidity 0.8.4;
interface BasicERC20 {
    function burn(uint256 value) external;
    function mint(address account, uint256 amount) external;
    function decimals() external view returns (uint8);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.4;
import "./OwnableUpgradeable.sol";

abstract contract IsOverridableUpgradable is OwnableUpgradeable {

    bool byPassable;
    mapping(address => mapping(bytes4 => bool)) byPassableFunction;
    mapping(address => mapping(uint256 => bool)) byPassableIds;

    modifier onlyOwner override {
        bool canBypass = byPassable && byPassableFunction[_msgSender()][msg.sig];
        require(owner() == _msgSender() || canBypass, "Not owner or able to bypass");
            _;
    }

    modifier canBypassId(uint256 id) {
        require (id != 0 && byPassableIds[_msgSender()][id], "Invalid id");
            _;
    }

    function toggleBypassability() public onlyOwner {
      byPassable = !byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            byPassableIds[who][id] = true;
        }        
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = false;
        if (id !=0) {
            byPassableIds[who][id] = true;
        }        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
    modifier onlyOwner() virtual {
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
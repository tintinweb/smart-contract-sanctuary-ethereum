// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;


import "./CA.sol";


contract Factory {
    event ERC20CATokenCreated(address tokenAddress);


    mapping(string =>address)private assets;
    mapping(uint256 =>address)private assetsIndex;
    uint256 counter;

    constructor(){
        counter = 0;
    }

    function deployNewERC20Token(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address ownerAddress
    ) public returns (address) {
        counter++;
        require(getAddressByName(name) == address(0),"Already Token Exits");
        ERC20 t = new ERC20(
            name,
            symbol,
            decimals,
            ownerAddress
        );
        assets[name] = address(t);
        assetsIndex[counter] = address(t);
        emit ERC20CATokenCreated(address(t));

        return address(t);
    }


    function getAddressByName(string memory name)public view returns(address)
    {
            return assets[name];
    }
 function getAddressByIndex(uint256 id)public view returns(address)
    {
            return assetsIndex[id];
    }





}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
   
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20 is IERC20, Ownable {
  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  string public name;
  string public symbol;
  uint256 public decimal;



  constructor(string memory _name, string memory _symbol,uint256 _decimal,address ownerAddress) {
    name = _name;
    symbol = _symbol;
    decimal = _decimal;
    transferOwnership(ownerAddress);
  }





  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function mint(address to,uint256 amount) external onlyOwner {
    _balances[to] += amount;
    _totalSupply += amount;
    emit Transfer(address(0), msg.sender, amount);
  }

  function burn(address from,uint256 amount) external onlyOwner {
      require(_balances[from] >= amount,"ERC20: burn amount exceeds balance");
    _balances[from] -= amount;
    _totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
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
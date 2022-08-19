// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC {
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function deposit() external payable;

  function withdraw(uint256) external;
}

interface IDexAggregator {
  function bestrateswap(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    address to
  ) external returns (uint256);
}

contract Index is Ownable {
  uint256 public thresholdamount = 20 * 1e18;
  uint256 public totaldeposit;
  uint256 public minimumdeposit = 1e15;
  address public constant weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

  uint256 public startblock;
  uint256 public endblock;
  mapping(address => uint256) balances;
  address public dex;

  struct IndexInfo {
    string name;
    address[] tokens;
    uint256[] percentages;
  }
  // instance of structure that stores the index details for this contract
  IndexInfo public indexinfo;

  // will initialize the index contract with name, token addresses and their corresponding percentages
  constructor(
    string memory _name,
    uint256[] memory _percentages,
    address[] memory _tokens,
    uint256 _blocks,
    address _dex
  ) {
    indexinfo.name = _name;
    indexinfo.tokens = _tokens;
    indexinfo.percentages = _percentages;
    startblock = block.number;
    endblock = startblock + _blocks;
    dex = _dex;
  }

  // will return the index info
  function Indexview() public view returns (IndexInfo memory) {
    return indexinfo;
  }

  // will update the index with the supplied inputs, can only be called by factory contract
  function udpateindex(
    string memory _name,
    uint256[] memory _percentages,
    address[] memory _tokens
  ) external onlyOwner {
    indexinfo.name = _name;
    indexinfo.tokens = _tokens;
    indexinfo.percentages = _percentages;
  }

  // returns index info after destructuring
  function getIndexInfo()
    public
    view
    returns (
      string memory,
      address[] memory,
      uint256[] memory
    )
  {
    return (indexinfo.name, indexinfo.tokens, indexinfo.percentages);
  }

  function depositEth() public payable {
    require(block.number <= endblock, "time limit passed");
    require(
      msg.value > minimumdeposit,
      "amount should be greater than 0.01 eth"
    );
    require(totaldeposit <= thresholdamount, "maturity amount exceeded");

    balances[msg.sender] += msg.value;
    totaldeposit += msg.value;
  }

  function checkBalance() public view returns (uint256[] memory) {
    uint256 n = indexinfo.tokens.length;
    IndexInfo memory indexa = indexinfo;
    uint256[] memory balancearray = new uint256[](n);

    address indexfund = address(this);

    for (uint256 i; i < n; i++) {
      balancearray[i] = IERC(indexa.tokens[i]).balanceOf(indexfund);
    }

    return balancearray;
  }

  function purchase() public {

    uint256 balance = address(this).balance;
    IERC(weth).deposit{ value: balance }();
    IERC(weth).approve(dex, IERC(weth).balanceOf(address(this)));

    uint256 numoftokens = indexinfo.tokens.length;
    IndexInfo memory indexa = indexinfo;
    for (uint256 i; i < numoftokens; i++) {
      IDexAggregator(dex).bestrateswap(
        weth,
        indexa.tokens[i],
        (balance * indexa.percentages[i]) / 1000,
        0,
        address(this)
      );
    }
  }

  


    function updatethreshold(uint _thresholdamount) public{
         
  
    thresholdamount=_thresholdamount;

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
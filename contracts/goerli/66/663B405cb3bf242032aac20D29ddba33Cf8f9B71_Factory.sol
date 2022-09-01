// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import { Index } from "./index.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IIndex.sol";

contract Factory
{
  //The indexInstanceArray will store the instance of the created index fund contract

  address[] public indexAddressArray;

  address public indexImplementation;

   

  //The indexIdByAddress will store the id of index by the address of index contract
  mapping(address => uint256) public indexIdByAddress;

  // Event for created index fund that will be called when an index fund contract is created
  event CreateIndexFund(
    address caller,
    uint256 id,
    string _name,
    uint256[] _percentages,
    address[] _tokens,
    uint256 _blocks,
    address dexaggregator
  );
  //Event for update index fund that will be called when an index fund contract is updated
  event UpdateIndexFund(
    address caller,
    uint256 id,
    string _name,
    uint256[] _percentages,
    address[] _tokens
  );

  constructor(){
        indexImplementation = address(new Index());


  }

  // It will initialize the pausable,ownable and uupsupgradable features
  

  //It can be used to pause the function
  

  //It can be used to unpause the function
  

  function setImplementation(address _implementation) public {
    indexImplementation = _implementation;
  }

  //This function will check the supplied inputs, creates a new index fund contract with them and stores the address of the function
  //inside the indexInstanceArray
  function createIndexFund(
    string calldata _name,
    uint256[] calldata _percentages,
    address[] memory _tokens,
    uint256 _blocks,
    address _token,
    address _dex
  ) external  {
    require(
      keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")),
      "Null name given"
    );
    require(
      _tokens.length == _percentages.length,
      "token array lengths should be equal to the percentage array length"
    );
    require(_tokens.length != 0, "tokens array should not be empty");

    require(_dex != address(0),"Dex address is zero");
    address implementation = indexImplementation;
    require(implementation != address(0), "implementation is set to zero address");
    // Index index = new Index(_name, _percentages, _tokens,_blocks,_dex);
    address indexAddress = Clones.clone(implementation);
    IndexInterface(indexAddress).initialize(_name,_percentages,_tokens,_blocks,_token,_dex);
    
    indexAddressArray.push(indexAddress);

    emit CreateIndexFund(
      msg.sender,
      indexAddressArray.length - 1,
      _name,
      _percentages,
      _tokens,
      _blocks,
      _dex
    );
  }

  //This function will update the indexfund contract based on the supplied index id and inputs
  function updateIndexFund(
    uint256 id,
    string calldata _name,
    uint256[] calldata _percentages,
    address[] calldata _tokens
  ) external  {
    require(id < indexAddressArray.length, "Id is greater than assigned ids");
    require(
      keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")),
      "Null name given"
    );
    require(_percentages.length != 0, "percentage array should not be empty");
    require(_tokens.length != 0, "tokens array should not be empty");
    require(
      _tokens.length == _percentages.length,
      "token array length should be equal to the percentage array length"
    );

    IndexInterface(indexAddressArray[id]).udpateindex(
      _name,
      _percentages,
      _tokens
    );

    emit UpdateIndexFund(msg.sender, id, _name, _percentages, _tokens);
  }

  //Get the index configurations like name, tokens and their percentages
  function getIndexInfo(uint256 id)
    public
    view
    returns (
      string memory name,
      address[] memory tokens,
      uint256[] memory percentage
    )
  {
    (name, tokens, percentage) = IndexInterface(indexAddressArray[id])
      .getIndexInfo();
    return (name, tokens, percentage);
  }

  //Returns the number of index contracts created
  function getNumberofindex() public view returns (uint256) {
    return indexAddressArray.length;
  }

  //Will be used to authorize the upgrade
  
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


interface IERC {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

    function getRates(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 flag
    ) external view returns (uint256[] memory, uint8);
}

contract Index is Ownable,Initializable {
    uint256 public maxdepositallowed;
    uint256 public minimumdepositallowed;
    uint256 public indexendingtime;
    uint256 public depositendingtime;
    uint256 public startingtime;
    uint256 public totaldeposit;
    address public weth;
    address public dex;
    address public usdc;
    mapping(address => uint256) balances;
    bool public purchased;
    bool public updated;
    struct IndexInfo {
        string name;
        address[] tokens;
        uint256[] percentages;
    }
    // instance of structure that stores the index details for this contract
    IndexInfo public indexinfo;
    IndexInfo public previous;

    

    
    // will initialize the index contract with name, token addresses and their corresponding percentages

    // will update the index with the supplied inputs, can only be called by factory contract
    function udpateindex(
        string memory _name,
        uint256[] memory _percentages,
        address[] memory _tokens
    ) external onlyOwner {
        
        previous=indexinfo;
        indexinfo = IndexInfo(_name, _tokens, _percentages);
        updated=true;
    }

    function updatename(string memory _name) external onlyOwner {
        previous.name=_name;
        indexinfo.name = _name;
        updated= true;
    }

    function updatepercent(uint256[] memory _percentages) external onlyOwner {
        previous.percentages= _percentages;
        indexinfo.percentages = _percentages;
        updated=true;
    }

    function updatetokens(address[] memory _tokens) external onlyOwner {
        previous.tokens=indexinfo.tokens;
        indexinfo.tokens = _tokens;
        updated=true;
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

    function getPrevInfo()
        public
        view
        returns (
            string memory,
            address[] memory,
            uint256[] memory
        )
    {
        return (previous.name, previous.tokens, previous.percentages);
    }

    function upadtepurchasetoken(address token1) public {
        usdc = token1;
    }

    function checkbalance(address token, address caller)
        internal
        view
        returns (uint)
    {
        return IERC(token).balanceOf(caller);
    }

    function deposit(uint256 amountin) public {
        require(block.number <= depositendingtime, "time limit passed");

        require(
            checkbalance(usdc, msg.sender) >= amountin &&
                amountin >= minimumdepositallowed,
            "amount should be greater than minimum"
        );
        require(totaldeposit <= maxdepositallowed, "Max amount exceeded");

        IERC(usdc).transferFrom(msg.sender, address(this), amountin);

        balances[msg.sender] += amountin;
        totaldeposit += amountin;
    }

    function indextokenbalance() public view returns (uint256[] memory) {
        uint256 n = indexinfo.tokens.length;
        IndexInfo memory indexa = indexinfo;
        uint256[] memory balancearray = new uint256[](n);

        

        for (uint256 i; i < n; i++) {
            balancearray[i] = balanceoftoken(indexa.tokens[i]);
        }

        return balancearray;
    }
  function balanceoftoken(address token) public view returns(uint){



    return IERC(token).balanceOf(address(this));
  }
    function purchase() public  {
        require(
            block.number > depositendingtime,
            "deposit period, no purchase allowed"
        );
        require(block.number<indexendingtime,"ending time already reached");
        require(!purchased,"already purchased");

        uint256 balance = totaldeposit;
        IERC(usdc).approve(dex, balance);

        uint256 numoftokens = indexinfo.tokens.length;
        IndexInfo memory indexa = indexinfo;
        for (uint256 i; i < numoftokens; i++) {
            IDexAggregator(dex).bestrateswap(
                usdc,
                indexa.tokens[i],
                (balance * indexa.percentages[i]) / 1000,
                0,
                address(this)
            );
        }
        purchased = true;
    }

    function sell() public {
        require(purchased, "Not purchased yet");
        require(block.number>indexendingtime,"The index has not ended yet");
        require(!updated,"rebalancing not done");
        IndexInfo memory indexa = indexinfo;
        uint256 numoftokens = indexinfo.tokens.length;
    
        for (uint256 i; i < numoftokens; i++) {
            uint256 balance = IERC(indexa.tokens[i]).balanceOf(address(this));
            
            IERC(indexa.tokens[i]).approve(dex, balance);
            IDexAggregator(dex).bestrateswap(
                indexa.tokens[i],
                usdc,
                balance,
                0,
                address(this)
            );
              
        }
    }

    function rebalancesell() public {
       require(
            block.number > depositendingtime,
            "deposit period, no rebalancing allowed"
        );
     require(block.number<indexendingtime,"ending time already reached");

        require(purchased,"not purchased yet");
        require(updated,"not updated");

        IndexInfo memory indexp = previous;
        uint256 numoftokens = previous.tokens.length;

        for (uint256 i; i < numoftokens; i++) {
            uint256 balance = IERC(indexp.tokens[i]).balanceOf(address(this));

            IERC(indexp.tokens[i]).approve(dex, balance);
            IDexAggregator(dex).bestrateswap(
                indexp.tokens[i],
                usdc,
                balance,
                0,
                address(this)
            );
        }
    }

    function rebalancepurchase() public {
        require(
            block.number > depositendingtime,
            "deposit period, no rebalancing allowed"
        );
                require(block.number<indexendingtime,"ending time already reached");

        require(purchased,"not purchased yet");
        
        uint256 balance_1 = IERC(usdc).balanceOf(address(this));
        IERC(usdc).approve(dex, balance_1);
        uint256 numoftokens_1 = indexinfo.tokens.length;
        IndexInfo memory indexa_1 = indexinfo;

        for (uint256 j; j < numoftokens_1; j++) 
        {
            IDexAggregator(dex).bestrateswap(
                usdc,
                indexa_1.tokens[j],
                (balance_1 * indexa_1.percentages[j]) / 1000,
                0,
                address(this)
            );
        }
        updated=false;
    }

    function indexProfitCalculator() public view returns (bool, uint256) {
        IndexInfo memory indexa = indexinfo;
        uint256 numoftokens = indexinfo.tokens.length;
        uint256[] memory total;
        uint256 totaldeposited = totaldeposit;

        uint256 sum;

        for (uint256 i; i < numoftokens; i++) {
            uint256 balance = IERC(indexa.tokens[i]).balanceOf(address(this));

            (total, ) = IDexAggregator(dex).getRates(
                indexa.tokens[i],
                usdc,
                balance,
                2
            );

            sum += total[0];
        }

        if (sum > totaldeposited) {
            return (true, sum - totaldeposited);
        }

        return (false, totaldeposited - sum);
    }

    function initialize(
        string memory _name,
        uint256[] memory _percentages,
        address[] memory _tokens,
        uint256 _blocks,
        address _usdc,
        address _dex
    ) public initializer {
        indexinfo = IndexInfo(_name, _tokens, _percentages);
        previous = IndexInfo(_name, _tokens, _percentages);
        startingtime = block.number;
        depositendingtime = startingtime + _blocks;
        indexendingtime=depositendingtime+_blocks;
        dex = _dex;
        usdc = _usdc;
        
    }

    // will return the index info
    function Indexview() public view returns (IndexInfo memory) {
        return indexinfo;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IndexInterface {
  // will return the index info

  // will update the index with the supplied inputs, can only be called by factory contract
  function udpateindex(
    string calldata _name,
    uint256[] calldata _percentages,
    address[] calldata _tokens
  ) external;

  function updatename(string calldata _name) external;

  function updatepercent(uint256[] calldata _percentages) external;

  function updatetokens(address[] calldata _tokens) external;

  // returns index info after destructuring
  function getIndexInfo()
    external
    view
    returns (
      string calldata,
      address[] calldata,
      uint256[] calldata
    );

  function deposit(uint256 amountin) external payable;

  function indextokenbalance() external view returns (uint256[] calldata);

  function purchase() external;

  function sell() external;

  function rebalancesimple() external;

  function initialize(
    string memory _name,
    uint256[] memory _percentages,
    address[] memory _tokens,
    uint256 _blocks,
    address _usdc,
    address _dex
  ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
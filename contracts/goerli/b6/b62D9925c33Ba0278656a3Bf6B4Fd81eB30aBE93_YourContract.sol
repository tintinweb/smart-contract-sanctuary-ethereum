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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

import {ISplitMain} from './interfaces/ISplitMain.sol';

contract YourContract is Ownable {
  /**
   * CONTRACT STATE
   */
  struct Project {
    bool splitAdded;

    string githubURL;
    address payable receiveMoneyAddress;
    address payable splitProxyAddress;

    uint32 communityPoolPercentage;
    address payable communityPoolAddress;

    string[] splitGithubURLs;
    uint32[] percentAllocations;
  }
  mapping(string => Project) public githubURLToProject;
  uint32 percentKeep;
  uint32 percentDistributorFee;
  string sinkGithubURL;

  ISplitMain splitMain;

  // @notice constant to scale uints into percentages (1e6 == 100%)
  // from 0xSplit contract
  uint32 public constant PERCENTAGE_SCALE = 1e6;

  // inputted percents must use PERCENTAGE_SCALE
  constructor(
    uint32 _percentKeep, 
    uint32 _percentDistributorFee, 
    address _splitMainAddress,
    string memory _sinkGithubURL
  ) {
    percentKeep = _percentKeep;
    percentDistributorFee = _percentDistributorFee;
    splitMain = ISplitMain(_splitMainAddress);
    sinkGithubURL = _sinkGithubURL;

    Project storage sinkProject = githubURLToProject[sinkGithubURL];
    sinkProject.splitAdded = true;
    sinkProject.githubURL = sinkGithubURL;
    sinkProject.receiveMoneyAddress = payable(msg.sender);
    sinkProject.splitProxyAddress = payable(msg.sender);
  }

  /**
   * CONTRACT METHODS
   */
  function addProjectToSystem( 
    string memory githubURL, 
    address payable receiveMoneyAddress,
    string[] memory splitGithubURLs,
    uint32[] memory percentAllocations,
    uint32 communityPoolPercentage,
    address payable communityPoolAddress
  ) public onlyOwner {

    // intialize the project object
    Project storage project = githubURLToProject[githubURL];
    project.githubURL = githubURL;
    project.receiveMoneyAddress = receiveMoneyAddress;
    project.splitGithubURLs = splitGithubURLs;
    project.percentAllocations = percentAllocations;
    project.communityPoolPercentage = communityPoolPercentage;
    project.communityPoolAddress = communityPoolAddress;

    // stores addresses of GitHub repos, address of team, and address of community pool
    address[] memory splitAddresses;
    uint32[] memory newPercentAllocations;
    if (communityPoolPercentage > 0) {
      // need an extra entry for community pool
      splitAddresses = new address[](splitGithubURLs.length+2);
      newPercentAllocations = new uint32[](splitGithubURLs.length+2);

      splitAddresses[splitGithubURLs.length+1] = communityPoolAddress;
      newPercentAllocations[splitGithubURLs.length+1] = communityPoolPercentage;
    } else {
      splitAddresses = new address[](splitGithubURLs.length+1);
      newPercentAllocations = new uint32[](splitGithubURLs.length+1);
    }

    // convert GitHub URLs to addresses
    for (uint i = 0; i < splitGithubURLs.length; i++) {
      string memory splitGithubURL = splitGithubURLs[i];
      Project storage splitProject = githubURLToProject[splitGithubURL];
      if (!splitProject.splitAdded) {
        // initializePlaceholderSplit(splitGithubURL);
      }
      require(splitProject.splitAdded, "split not added");
      splitAddresses[i] = splitProject.splitProxyAddress;
      newPercentAllocations[i] = percentAllocations[i];
    }

    // add self + kept percentage
    splitAddresses[splitGithubURLs.length] = receiveMoneyAddress;
    newPercentAllocations[splitGithubURLs.length] = percentKeep;

    // assert sum of percentAllocations is PERCENTAGE_SCALE
    uint32 sum = 0;
    for (uint i = 0; i < newPercentAllocations.length; i++) {
      require(newPercentAllocations[i] > 0, "percentAllocations must be greater than 0");
      sum += newPercentAllocations[i];
    }
    require(sum == PERCENTAGE_SCALE, "sum of percentAllocations is not 1e6");

    // sort addresses and percent allocations
    for (uint i = 0; i < splitAddresses.length; i++) {
      for (uint j = i + 1; j < splitAddresses.length; j++) {
        if (splitAddresses[i] > splitAddresses[j]) {
          (splitAddresses[i], splitAddresses[j]) = (splitAddresses[j], splitAddresses[i]);
          (newPercentAllocations[i], newPercentAllocations[j]) = (newPercentAllocations[j], newPercentAllocations[i]);
        }
      }
    }

    // // create or update split proxy for this GitHub
    // if (!project.splitAdded) {
    //   project.splitProxyAddress = payable(splitMain.createSplit(
    //     splitAddresses, 
    //     newPercentAllocations, 
    //     percentDistributorFee, 
    //     address(this)
    //   ));
    //   project.splitAdded = true;
    // } else {
    //   splitMain.updateSplit(
    //     project.splitProxyAddress, 
    //     splitAddresses, 
    //     newPercentAllocations, 
    //     percentDistributorFee
    //   );
    // }
  }

  function initializePlaceholderSplit(string memory githubURL) internal {   
    Project storage project = githubURLToProject[githubURL];
    project.githubURL = githubURL;

    require(!project.splitAdded, "placeholder split already added");
    
    // set up a dummy split to start out so we can get the address of the split
    // 0xSplits requires splits are between 2 or more addresses
    uint32[] memory placeholderPercentage = new uint32[](2);
    placeholderPercentage[0] = PERCENTAGE_SCALE-1;
    placeholderPercentage[1] = uint32(1);
    
    address[] memory placeholderAddresses = new address[](2);
    if (owner() > address(this)) {
      placeholderAddresses[0] = address(this);
      placeholderAddresses[1] = owner();
    } else {
      placeholderAddresses[1] = address(this);
      placeholderAddresses[0] = owner();
    }
    
    // create initial split
    project.splitProxyAddress = payable(splitMain.createSplit(
      placeholderAddresses, 
      placeholderPercentage, 
      percentDistributorFee, 
      address(this)
    ));

    // reroute all payments back to the split
    if (project.splitProxyAddress > owner()) {
      placeholderAddresses[0] = owner();
      placeholderPercentage[0] = uint32(1);
      placeholderAddresses[1] = project.splitProxyAddress;
      placeholderPercentage[1] = PERCENTAGE_SCALE-1;
    } else {
      placeholderAddresses[1] = owner();
      placeholderPercentage[1] = uint32(1);
      placeholderAddresses[0] = project.splitProxyAddress;
      placeholderPercentage[0] = PERCENTAGE_SCALE-1;
    }

    splitMain.updateSplit(
      project.splitProxyAddress, 
      placeholderAddresses, 
      placeholderPercentage, 
      percentDistributorFee
    );
    project.splitAdded = true;
  }

  // if 0.5% is too little or too much for the system to work, owner can change it
  function changePercentageDistributorFee(uint32 _newPercentDistributorFee) public onlyOwner {
    percentDistributorFee = _newPercentDistributorFee;
  }

  // transfer ownership of contract and change address of sink URL
  function transferOwnership(address newOwner) public override onlyOwner {
    super.transferOwnership(newOwner);
    githubURLToProject[sinkGithubURL].splitProxyAddress = payable(newOwner);
  }

  /**
   * CONTRACT GETTERS
   */
  function getProject(string memory githubURL) external view returns (Project memory) {
    return githubURLToProject[githubURL];
  }

  function getSinkGithubURL() external view returns (string memory) {
    return sinkGithubURL;
  }
  
  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {ERC20} from '@rari-capital/solmate/src/tokens/ERC20.sol';

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}
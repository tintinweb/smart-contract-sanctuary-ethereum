pragma solidity ^0.8.4;

import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IOptiVault {
  function initialize(address _token, uint256 _lockupDate, uint256 _minimumTokenCommitment, uint256 _withdrawalsLockedUntilTimestamp, address _balanceLookup) external;
}

contract GroupLP {
  receive() external payable {}

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant operations = 0x133A5437951EE1D312fD36a74481987Ec4Bf8A96;
  address private constant optiVaultMaster = 0xC5A00A96E6a7039daD5af5c41584469048B26038; // Address to clone OptiVault from

  IERC20 public token;                                   // Token to add LP for
  address public tokenSupplier;                          // Supplier of token
  uint256 public committedTokenAmount;                   // Amount to match
  uint256 public goalDate;                               // Date by which to complete the campaign
  uint256 public withdrawalsLockedDuration;              // Proposed duration of OptiVault lock
  uint256 public withdrawalsLockedUntilTimestamp;        // End time plus Duration
  IUniswapV2Pair private pair;                           // Pair to add to
  bool private initialized;                              // Campaign pamaters hav been set
  bool public campaignFailed;                            // Allows recovery of ETH under failure conditions

  mapping (address => uint256) public ethContributionOf; // Used as numerator for calculating users shares
  uint256 public totalFundingRaised;                     // Used as denominator for calculating users shares

  uint256 public mintedLP;                               // Amount of LP that has been minted
  address public optiVault;                              // cloned OptiVault contract that holds the minted LP

  function initialize(address _pair, address _tokenSupplier, uint256 _goalDate, uint256 _withdrawalsLockedDuration,  uint256 _commitment) external payable {
    require(!initialized, "GroupLP: Already initialized");
    committedTokenAmount = _commitment;
    pair = IUniswapV2Pair(_pair);
    token = (pair.token0() == WETH) ? IERC20(pair.token1()) : IERC20(pair.token0());
    goalDate = _goalDate;
    withdrawalsLockedDuration = _withdrawalsLockedDuration;
    tokenSupplier = _tokenSupplier;
    ethContributionOf[tokenSupplier] = msg.value;
    totalFundingRaised = msg.value; 
    initialized = true;
  }

  function supplierHasCommitedBalance() public view returns (bool valid) {
    // Campaign is valid IFF: (Commited tokens <= Supplier approval <= Supplier balance)
    uint256 approval = token.allowance(tokenSupplier, address(this));
    uint256 balance = token.balanceOf(tokenSupplier);
    valid = committedTokenAmount <= approval && approval <= balance;
  }

  function getReserves() internal view returns (uint256 ethReserves, uint256 tokenReserves) {
    (uint reserveA, uint reserveB, ) = pair.getReserves();
    (ethReserves, tokenReserves) = WETH < address(token) ? (reserveA, reserveB) : (reserveB, reserveA);
  }

  function uniswapQuote(uint amountToken) internal view returns (uint256 amountEth) {
    (uint256 ethReserves, uint256 tokenReserves) = getReserves();
    amountEth = amountToken * ethReserves / tokenReserves;
  }  

  function ethMatchEstimate() public view returns (uint256 ethGoal) {
    ethGoal = uniswapQuote(committedTokenAmount) * 1005 / 1000;
  }

  function fund() public payable {
    require(supplierHasCommitedBalance(), "GroupLP: Supplier is missing tokens");
    require(!campaignFailed, "GroupLP: Campaign failed, use recoverETH");
    require((ethMatchEstimate() * 110) / 100 >= address(this).balance, "GroupLP: Over funded!");
    ethContributionOf[msg.sender] += msg.value;
    totalFundingRaised += msg.value;
  }

  function endFailedCampaign() public {
    // Either the campaign is invalid (token supplier's balance or approval has fallen beneath the committed tokens)
    // Or the campaign goalDate is past with no LP created
    require(!campaignFailed, "GroupLP: Campaign already failed.");
    require(mintedLP == 0, "GroupLP: LP already added!");
    bool campaignHasExpired = (block.timestamp > (goalDate + 1 hours));
    if (!supplierHasCommitedBalance() || campaignHasExpired) {
      campaignFailed = true;
    }
  }

  function readyToMint() public view returns (bool ready) {
    require(address(this).balance >= ethMatchEstimate(), "GroupLP: Campaign needs more ETH to match supplier's committed tokens");
    require(supplierHasCommitedBalance(), "GroupLP: Supplier's token balance or approval has fallen below the required amount.");
    return true;
  }

  function supplyLP(uint minimumEth) public returns (uint256 amountToken, uint256 amountETH) {
    require(msg.sender == operations);
    require(readyToMint());
    address pairAddress = address(pair);
    uint256 tokenBalanceOfPairPreSupply = token.balanceOf(pairAddress);
    TransferHelper.safeTransferFrom(address(token), tokenSupplier, pairAddress, committedTokenAmount);
    uint256 tokenBalanceOfPairPostSupply = token.balanceOf(pairAddress);
    amountToken = tokenBalanceOfPairPostSupply - tokenBalanceOfPairPreSupply; 
    amountETH = uniswapQuote(amountToken); 
    require(amountETH >= minimumEth, "GroupLP: Tokens must be valued at least the minimum Eth"); 
    IWETH(WETH).deposit{value: amountETH}();
    assert(IWETH(WETH).transfer(pairAddress, amountETH));

    withdrawalsLockedUntilTimestamp = block.timestamp + withdrawalsLockedDuration;
    optiVault = Clones.clone(optiVaultMaster);
    mintedLP = IUniswapV2Pair(pairAddress).mint(optiVault);
    payable(operations).transfer(address(this).balance); //Excess ETH to operations
    IOptiVault(optiVault).initialize(pairAddress, 0, 0, withdrawalsLockedUntilTimestamp, address(this));
  }

  function recoverETH() public {
    require(campaignFailed, "GroupLP: Campaign is active. Use withdrawLP.");
    require(ethContributionOf[msg.sender] > 0, "GroupLP: You have recovered all your ETH");
    payable(msg.sender).transfer(ethContributionOf[msg.sender]);
    ethContributionOf[msg.sender] == 0;
  }

  function contributionOf(address user) external view returns (uint256 _ethBalance) {
    _ethBalance = ethContributionOf[user];
  }

  function sharesOf(address user) external view returns (uint256 _lpTokenShare) {
    _lpTokenShare = (mintedLP / 2) * ethContributionOf[user] / totalFundingRaised;
    if (user == tokenSupplier) {
      _lpTokenShare += mintedLP / 2;
    }
  }

}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
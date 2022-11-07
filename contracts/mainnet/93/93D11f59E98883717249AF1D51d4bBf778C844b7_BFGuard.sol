/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}


// File @gnosis.pm/safe-contracts/contracts/common/[email protected]

pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}


// File @gnosis.pm/safe-contracts/contracts/base/[email protected]

pragma solidity >=0.7.0 <0.9.0;


interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/guard/guard.sol

pragma solidity ^0.8.0;


/**
 * @notice now used for gbpt mint.
 * would check chainlink feed.
 */

contract BFGuard is Guard{

  //////////////////// constant

  ////////// GBPT
  // mainnet gbpt address: 0x86B4dBE5D203e634a12364C0e428fa242A3FbA98
  IERC20 immutable public GBPT;
  AggregatorV3Interface immutable public GBPTChainlinkAggregator;
  uint256 immutable public GBPTChainlinkUpdateHeartbeat;
  uint8 immutable public ChainLinkGBPDecimal;  

  // function issue(uint256 amount, string data) returns()
  bytes4 constant public GBPTIssueFuncSign = 0x9169d937;

  // 4(func sign size) + 32(amount size) + 32(encode string size flag) + 32(string size flag) + X(string size)
  uint256 constant public GBPTIssueDataMinLength = 4 + 32 + 32 + 32;

  //////////////////// func

  constructor(address _gbptAddr, address _gbptChainlinkAggregatorAddr, uint256 _gbptHeartbeat, uint8 _chainLinkGBPdecimal) {
    GBPT = IERC20(_gbptAddr);
    GBPTChainlinkAggregator = AggregatorV3Interface(_gbptChainlinkAggregatorAddr);
    GBPTChainlinkUpdateHeartbeat = _gbptHeartbeat;
    ChainLinkGBPDecimal = _chainLinkGBPdecimal;
  }

  function _checkGBPTIssue(bytes memory data) internal view {

    // not issue data.
    if(data.length < GBPTIssueDataMinLength){
      return;
    }
    
    bytes4 selector;
    uint256 amount;
    
    assembly {
      selector := mload(add(data, 32))
        amount := mload(add(data, 36))
    }

    if(selector != GBPTIssueFuncSign){
      return;
    }

    if(amount == 0){
      return;
    }

    require(ChainLinkGBPDecimal == GBPTChainlinkAggregator.decimals(), "Unexpected decimals of PoR feed");

    (, int256 signedReserves, , uint256 updatedAt, ) = GBPTChainlinkAggregator.latestRoundData();
    require(signedReserves > 0, "GBPT: Invalid answer from PoR feed");
    uint256 reserves = uint256(signedReserves);

    require(updatedAt <= block.timestamp && updatedAt >= block.timestamp - GBPTChainlinkUpdateHeartbeat, "GBPT: PoR answer is old or future");

    require(GBPT.totalSupply() + amount <= reserves, "GBPT: total supply would exceed reserves after mint");

    return;
  }
  
  function checkTransaction(
                            address to,
                            uint256,
                            bytes memory data,
                            Enum.Operation,
                            uint256 ,
                            uint256 ,
                            uint256 ,
                            address ,
                            address payable,
                            bytes memory ,
                            address 
                            ) external override view {
    if(to == address(GBPT)){
      _checkGBPTIssue(data);
    }

    return;
  }

  function checkAfterExecution(bytes32 , bool ) external pure override{
    return;
  }
}
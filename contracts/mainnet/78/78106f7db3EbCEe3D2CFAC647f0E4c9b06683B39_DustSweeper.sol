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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Trustus.sol";

/// @title DustSweeper
/// @notice Allows users to swap small balance tokens for ETH without expensive gas transactions
contract DustSweeper is Ownable, ReentrancyGuard, Trustus {
  using SafeTransferLib for ERC20;

  /// @notice Events
  event Sweep(address indexed makerAddress, address indexed tokenAddress, uint256 tokenAmount, uint256 ethAmount);
  event ProtocolPayout(uint256 protocolSplit, uint256 governorSplit);
  /// @notice Errors
  error ZeroAddress();
  error NoBalance();
  error NotContract();
  error NoTokenPrice(address tokenAddress);
  error NoSweepableOrders();
  error InsufficientNative(uint256 sendAmount, uint256 remainingBalance);
  error OutOfRange(uint256 param);

  struct Token {
    bool tokenSetup;
    uint8 decimals;
    uint8 takerDiscountTier;
  }

  struct CurrentToken {
    address tokenAddress;
    uint8 decimals;
    uint256 price;
  }

  struct TokenPrice {
    address addr;
    uint256 price;
  }

  struct Native {
    uint256 balance;
    uint256 total;
    uint256 protocol;
  }

  struct Order {
    uint256 nativeAmount;
    uint256 tokenAmount;
    uint256 distributionAmount;
    address payable destinationAddress;
  }

  address payable public protocolWallet;
  address payable public governorWallet;
  uint256 public protocolFee;
  uint256 public protocolPayoutSplit;

  mapping(address => Token) private tokens;
  mapping(uint8 => uint256) public takerDiscountTiers;
  mapping(address => address payable) public destinations;

  /// @notice Trustus Packet Request
  bytes32 public constant TRUSTUS_REQUEST_VALUE = 0xfc7ecbf4f091085173dad8d1d3c2dfd218c018596a572201cd849763d1114e7a;

  /// @notice Whitelist
  bool public sweepWhitelistOn;
  mapping(address => bool) public sweepWhitelist;

  /// @notice Limits
  uint256 public constant MAX_TAKER_DISCOUNT_PCT = 10000;
  uint256 public constant MAX_PROTOCOL_FEE_PCT = 5000;
  uint256 public constant MAX_PROTOCOL_PAYOUT_SPLIT_PCT = 10000;
  uint256 public constant MIN_OVERAGE_RETURN_WEI = 7000;
  uint256 public constant MAX_SWEEP_ORDER_SIZE = 200;

  constructor(
    address payable _protocolWallet,
    address payable _governorWallet,
    uint256[] memory _takerDiscountTiers,
    uint256 _protocolFeePercent,
    uint256 _protocolPayoutSplitPercent
  ) {
    // Check Input
    if (_protocolWallet == address(0))
      revert ZeroAddress();
    if (_governorWallet == address(0))
      revert ZeroAddress();
    if (_protocolFeePercent > MAX_PROTOCOL_FEE_PCT)
      revert OutOfRange(_protocolFeePercent);
    if (_protocolPayoutSplitPercent > MAX_PROTOCOL_PAYOUT_SPLIT_PCT)
      revert OutOfRange(_protocolPayoutSplitPercent);
    // Taker Discount Tiers
    uint256 _takerDiscountTierslength = _takerDiscountTiers.length;
    for (uint8 t = 0;t < _takerDiscountTierslength;++t) {
      if (_takerDiscountTiers[t] > MAX_TAKER_DISCOUNT_PCT)
        revert OutOfRange(_takerDiscountTiers[t]);
      takerDiscountTiers[t] = _takerDiscountTiers[t];
    }
    // Wallets
    protocolWallet = _protocolWallet;
    governorWallet = _governorWallet;
    // Protocol Fee %
    protocolFee = _protocolFeePercent;
    // Protocol Payout Split Percent
    protocolPayoutSplit = _protocolPayoutSplitPercent;
  }

  /// @notice Method that is called by taker bots to exchange ETH for a list of ERC20 tokens at a discount
  /// @dev Taker bot needs to call offchain API to get packet with current price data for tokens they intend to sweep
  /// @dev makers & tokenAddresses are mapped and need to be the same size
  /// @dev tokenAddresses[0] is the ERC20 token address that will be swept from makers[0], tokenAddresses[1] corresponds with makers[1]...
  /// @param makers List of maker addresses that have approved an ERC20 token and taker bot intends to sweep
  /// @param tokenAddresses List of ERC20 tokenAddresses that correspond with makers list to be swept
  /// @param packet The packet that contains current prices for tokens the taker bot intends to sweep, is generated and signed offchain using API
  function sweepDust(
    address[] calldata makers,
    address[] calldata tokenAddresses,
    TrustusPacket calldata packet
  ) external payable nonReentrant verifyPacket(TRUSTUS_REQUEST_VALUE, packet) {
    // Check whitelist
    if (sweepWhitelistOn && !sweepWhitelist[msg.sender])
      revert NoSweepableOrders();
    TokenPrice[] memory tokenPrices = abi.decode(packet.payload, (TokenPrice[]));
    Native memory native = Native(msg.value, 0, 0);
    // Order is valid length
    uint256 makerLength = makers.length;
    if (makerLength == 0 || makerLength > MAX_SWEEP_ORDER_SIZE || makerLength != tokenAddresses.length)
      revert NoSweepableOrders();
    CurrentToken memory currentToken = CurrentToken(address(0), 0, 0);
    for (uint256 i = 0; i < makerLength; ++i) {
      Order memory order = Order(0, 0, 0, payable(address(0)));
      // Get tokenAmount to be swept
      order.tokenAmount = getTokenAmount(tokenAddresses[i], makers[i]);
      if (order.tokenAmount <= 0)
        continue;

      if (currentToken.tokenAddress != tokenAddresses[i]) {
        currentToken.tokenAddress = tokenAddresses[i];
        // Setup Token if needed
        if (!tokens[tokenAddresses[i]].tokenSetup)
          setupToken(tokenAddresses[i]);
        // Get tokenDecimals
        currentToken.decimals = getTokenDecimals(tokenAddresses[i]);
        // Get tokenPrice
        currentToken.price = getPrice(tokenAddresses[i], tokenPrices);
        if (currentToken.price == 0)
          revert NoTokenPrice(tokenAddresses[i]);
      }

      // DustSweeper sends Maker's tokens to Taker
      ERC20(tokenAddresses[i]).safeTransferFrom(makers[i], msg.sender, order.tokenAmount);

      // Equivalent amount of Native Tokens
      order.nativeAmount = ((order.tokenAmount * currentToken.price) / (10**currentToken.decimals));
      native.total += order.nativeAmount;

      // Amount of Native Tokens to transfer
      order.distributionAmount = (order.nativeAmount * (1e4 - takerDiscountTiers[getTokenTakerDiscountTier(tokenAddresses[i])])) / 1e4;
      if (order.distributionAmount > native.balance)
        revert InsufficientNative(order.distributionAmount, native.balance);
      // Subtract order.distributionAmount from native.balance amount
      native.balance -= order.distributionAmount;

      // If maker has specified a destinationAddress send ETH there otherwise send to maker address
      order.destinationAddress = destinations[makers[i]] == address(0) ? payable(makers[i]) : destinations[makers[i]];
      // Taker sends Native Token to Maker
      SafeTransferLib.safeTransferETH(order.destinationAddress, order.distributionAmount);
      // Log Event
      emit Sweep(makers[i], tokenAddresses[i], order.tokenAmount, order.distributionAmount);
    }
    // Taker pays protocolFee % for the total amount to avoid multiple transfers
    native.protocol = (native.total * protocolFee) / 1e4;
    if (native.protocol > native.balance)
      revert InsufficientNative(native.protocol, native.balance);
    // Subtract protocolFee from native.balance and leave in contract
    native.balance -= native.protocol;

    // Pay any overage back to msg.sender as long as overage > MIN_OVERAGE_RETURN_WEI
    if (native.balance > MIN_OVERAGE_RETURN_WEI) {
      SafeTransferLib.safeTransferETH(payable(msg.sender), native.balance);
    }
  }

  /// @notice Calculates the amount of ERC20 token to be swept
  /// @dev If balance is lower than allowance will return balance, otherwise entire allowance is returned
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _makerAddress Address of the maker to fetch allowance/balance for specified ERC20 token
  /// @return The amount of the specified ERC20 token that can be swept
  function getTokenAmount(address _tokenAddress, address _makerAddress) private view returns(uint256) {
    // Check Allowance
    uint256 allowance = ERC20(_tokenAddress).allowance(_makerAddress, address(this));
    if (allowance == 0)
      return 0;
    uint256 balance = ERC20(_tokenAddress).balanceOf(_makerAddress);
    return balance < allowance ? balance : allowance;
  }

  /// @notice Fetches price for specified ERC20 token using the signed price packets
  /// @dev Iterates through the tokens/prices in the attached Trustus price packet, returns 0 if not found
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _tokenPrices Array of TokenPrice structs generated and signed offchain
  /// @return Price in ETH of the specified ERC20 token
  function getPrice(address _tokenAddress, TokenPrice[] memory _tokenPrices) private pure returns(uint256) {
    uint256 tokenPricesLength = _tokenPrices.length;
    for (uint256 i = 0;i < tokenPricesLength;++i) {
      if (_tokenAddress == _tokenPrices[i].addr) {
        return _tokenPrices[i].price;
      }
    }
    return 0;
  }

  /// @notice Does first time setup of specified ERC20 token including caching decimals value from token contract
  /// @dev Attempts to fetch and cache the decimals value using the decimals() method on token contract, defaults to 18
  /// @param _tokenAddress Address of the ERC20 token to set up
  function setupToken(address _tokenAddress) public {
    (bool success, bytes memory result) = _tokenAddress.staticcall(abi.encodeWithSignature("decimals()"));
    uint8 decimals = 18;
    if (success)
      decimals = abi.decode(result, (uint8));
    tokens[_tokenAddress].tokenSetup = true;
    tokens[_tokenAddress].decimals = decimals;
  }

  /// @notice Returns the cached decimals value for the specified ERC20 token
  /// @dev This value is cached by calling decimals() method on ERC20 token contract during setupToken()
  /// @param _tokenAddress Address of the ERC20 token
  /// @return Decimals value for the specified ERC20 token
  function getTokenDecimals(address _tokenAddress) public view returns(uint8) {
    return tokens[_tokenAddress].decimals;
  }

  /// @notice Returns the takerDiscountTier for the specified ERC20 token
  /// @dev Use this method in conjunction with takerDiscountTiers(tier) to get the takerDiscount percent
  /// @param _tokenAddress Address of the ERC20 token
  /// @return takerDiscountTier that the specified ERC20 belongs to
  function getTokenTakerDiscountTier(address _tokenAddress) public view returns(uint8) {
    return tokens[_tokenAddress].takerDiscountTier;
  }

  /// @notice Allows makers to specify a different address for takers to send ETH to in exchange for ERC20 tokens
  /// @dev This needs to be called by the maker before the sweepDust of approved tokens takes place
  /// @param _destinationAddress The target address to receive distribution amount from taker, if not set will send to maker address
  function setDestinationAddress(address _destinationAddress) external {
    if (_destinationAddress == address(0))
      revert ZeroAddress();
    destinations[msg.sender] = payable(_destinationAddress);
  }

  /// @notice Set the token decimal field for the specified ERC20 token
  /// @dev The decimals field should be filled via the token contract decimals() method on token setup
  /// @dev If the decimals field is incorrect or not filled properly this method can be used to set it
  /// @param _tokenAddress Address of ERC20 token to update decimals field for
  /// @param _decimals The decimal value for the specified ERC20 token (valid range: 0-18)
  function setTokenDecimals(address _tokenAddress, uint8 _decimals) external onlyOwner {
    if (_tokenAddress == address(0))
      revert ZeroAddress();
    tokens[_tokenAddress].decimals = _decimals;
  }

  /// @notice Change the taker fee tier for the specified ERC20 token
  /// @dev Tokens start in the default taker fee tier (0) but tokens can be switched to low (1) or high (2) fee tiers
  /// @param _tokenAddress Address of the ERC20 token
  /// @param _tier Tier to assign to specified ERC20 token, must be a valid tier (non zero taker fee value in takerDiscountTiers)
  function setTokenTakerDiscountTier(address _tokenAddress, uint8 _tier) external onlyOwner {
    if (_tokenAddress == address(0))
      revert ZeroAddress();
    if (takerDiscountTiers[_tier] == 0)
      revert OutOfRange(_tier);
    tokens[_tokenAddress].takerDiscountTier = _tier;
  }

  /// @notice Used to calculate the discount percent given to the taker bot for sweeping tokens
  /// @dev This method can be used to add a new taker fee tier or adjust existing tier value
  /// @param _takerDiscountPercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 1-10000)
  /// @param _tier Tier to update
  function setTakerDiscountPercent(uint256 _takerDiscountPercent, uint8 _tier) external onlyOwner {
    if (_takerDiscountPercent == 0 || _takerDiscountPercent > MAX_TAKER_DISCOUNT_PCT)
      revert OutOfRange(_takerDiscountPercent);
    takerDiscountTiers[_tier] = _takerDiscountPercent;
  }

  /// @notice Set the percent that the taker bot pays out to the protocol in ETH
  /// @dev Protocol fee is calculated by taking the total ETH value of tokens multiplied by protocolFee
  /// @param _protocolFeePercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 0-5000)
  function setProtocolFeePercent(uint256 _protocolFeePercent) external onlyOwner {
    if (_protocolFeePercent > MAX_PROTOCOL_FEE_PCT)
      revert OutOfRange(_protocolFeePercent);
    protocolFee = _protocolFeePercent;
  }

  /// @notice Change the address of the protocol wallet
  /// @dev Split for payout of protocolWallet is determined by protocolPayoutSplit value
  /// @param _protocolWallet Address where the contract will send protocol split of collected fees to
  function setProtocolWallet(address payable _protocolWallet) external onlyOwner {
    if (_protocolWallet == address(0))
      revert ZeroAddress();
    protocolWallet = _protocolWallet;
  }

  /// @notice Change the address of the governor wallet
  /// @dev Split for payout of governorWallet is determined by sending balance left after protocolWallet is paid
  /// @param _governorWallet Address where the contract will send governor split of collected fees to
  function setGovernorWallet(address payable _governorWallet) external onlyOwner {
    if (_governorWallet == address(0))
      revert ZeroAddress();
    governorWallet = _governorWallet;
  }

  /// @notice Sets the percentage of protocol fees that are sent to protocol wallet
  /// @dev Protocol fees are split between protocolWallet & governorWallet
  /// @dev Setting this to 10000 (100%) sends all fees to protocolWallet
  /// @dev Setting this to 0 (0%) sends all fees to governorWallet
  /// @param _protocolPayoutSplitPercent Percent * 100, 100% == 10000, 50% == 5000 (valid range: 0-10000)
  function setProtocolPayoutSplit(uint256 _protocolPayoutSplitPercent) external onlyOwner {
    if (_protocolPayoutSplitPercent > MAX_PROTOCOL_PAYOUT_SPLIT_PCT)
      revert OutOfRange(_protocolPayoutSplitPercent);
    protocolPayoutSplit = _protocolPayoutSplitPercent;
  }

  /// @notice Adds or removes addresses from the trusted signer list
  /// @dev Addresses that are set to true in Trustus.isTrusted mapping are allowed to sign offchain price packets
  /// @param _trustedProviderAddress Address to add/remove from the isTrusted list used for offchain signing
  function toggleIsTrusted(address _trustedProviderAddress) external onlyOwner {
    if (_trustedProviderAddress == address(0))
      revert ZeroAddress();
    bool _isTrusted = isTrusted[_trustedProviderAddress] ? false : true;
    _setIsTrusted(_trustedProviderAddress, _isTrusted);
  }

  /// @notice Checks if specified address is a trusted signer
  /// @dev A getter function which can be used to see if address is in the internal isTrusted mapping
  /// @param _trustedProviderAddress Address to check against isTrusted mapping
  /// @return True if address is in isTrusted mapping, false otherwise
  function getIsTrusted(address _trustedProviderAddress) external view returns(bool) {
    return isTrusted[_trustedProviderAddress];
  }

  /// @notice Turns on/off the taker bot whitelist
  /// @dev If this is turned on only whitelisted addresses will be able to run the sweepDust method
  function toggleSweepWhitelist() external onlyOwner {
    sweepWhitelistOn = sweepWhitelistOn ? false : true;
  }

  /// @notice Adds or removes addresses from taker bot whitelist
  /// @dev Get the status of whitelisted addresses using sweepWhitelist(address)
  /// @param _whitelistAddress Address of taker bot to whitelist
  function toggleSweepWhitelistAddress(address _whitelistAddress) external onlyOwner {
    if (_whitelistAddress == address(0))
      revert ZeroAddress();
    sweepWhitelist[_whitelistAddress] = sweepWhitelist[_whitelistAddress] ? false : true;
  }

  /// @notice Use this method to pay out accumulated protocol fees
  /// @dev ETH protocol fees stored in contract are split between protocolWallet & governorWallet based on protocolPayoutSplit
  function payoutProtocolFees() external nonReentrant {
    uint256 balance = address(this).balance;
    if (balance <= 0)
      revert NoBalance();
    // Protocol Split
    uint256 protocolSplit = (balance * protocolPayoutSplit) / 1e4;
    if (protocolSplit > 0)
      SafeTransferLib.safeTransferETH(protocolWallet, protocolSplit);
    // Governor Split
    uint256 governorSplit = address(this).balance;
    if (governorSplit > 0)
      SafeTransferLib.safeTransferETH(governorWallet, governorSplit);
    emit ProtocolPayout(protocolSplit, governorSplit);
  }

  /// @notice Used to withdraw any ERC20 tokens that have been sent to contract
  /// @dev No ERC20 tokens should be sent but this method prevents tokens being locked in contract
  /// @param _tokenAddress Address of token to be withdrawn from contract
  function withdrawToken(address _tokenAddress) external onlyOwner {
    uint256 tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
    if (tokenBalance <= 0)
      revert NoBalance();
    ERC20(_tokenAddress).safeTransfer(msg.sender, tokenBalance);
  }

  receive() external payable {}
  fallback() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Trustus
/// @author zefram.eth
/// @notice Trust-minimized method for accessing offchain data onchain
abstract contract Trustus {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param v Part of the ECDSA signature
    /// @param r Part of the ECDSA signature
    /// @param s Part of the ECDSA signature
    /// @param request Identifier for verifying the packet is what is desired
    /// , rather than a packet for some other function/contract
    /// @param deadline The Unix timestamp (in seconds) after which the packet
    /// should be rejected by the contract
    /// @param payload The payload of the packet
    struct TrustusPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 request;
        uint256 deadline;
        bytes payload;
    }

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Trustus__InvalidPacket();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records whether an address is trusted as a packet provider
    /// @dev provider => value
    mapping(address => bool) internal isTrusted;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// Will revert if the packet is invalid.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    modifier verifyPacket(bytes32 request, TrustusPacket calldata packet) {
        if (!_verifyPacket(request, packet)) revert Trustus__InvalidPacket();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    /// @return success True if the packet is valid, false otherwise
    function _verifyPacket(bytes32 request, TrustusPacket calldata packet)
    internal
    virtual
    returns (bool success)
    {
        // verify deadline
        if (block.timestamp > packet.deadline) return false;

        // verify request
        if (request != packet.request) return false;

        // verify signature
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "VerifyPacket(bytes32 request,uint256 deadline,bytes payload)"
                            ),
                            packet.request,
                            packet.deadline,
                            packet.payload
                        )
                    )
                )
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return (recoveredAddress != address(0)) && isTrusted[recoveredAddress];
    }

    /// @notice Sets the trusted status of an offchain data provider.
    /// @param signer The data provider's ECDSA public key as an Ethereum address
    /// @param isTrusted_ The desired trusted status to set
    function _setIsTrusted(address signer, bool isTrusted_) internal virtual {
        isTrusted[signer] = isTrusted_;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
        block.chainid == INITIAL_CHAIN_ID
        ? INITIAL_DOMAIN_SEPARATOR
        : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Trustus"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}
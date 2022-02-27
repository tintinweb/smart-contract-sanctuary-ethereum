// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof

/// @notice Contract for facilitating a whitelisted airdrop and token sale
/// @dev Consider using reentrancy guard, context, other standard libraries
contract MembershipContract {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /*///////////////////////////////////////////////////////////////
                          IMMUTABLE STORAGE
  //////////////////////////////////////////////////////////////*/

  bytes32 public immutable merkleRoot;

  /*///////////////////////////////////////////////////////////////
                          MUTABLE STORAGE
  //////////////////////////////////////////////////////////////*/

  address owner;
  address usdcTokenContract;
  address sampleTokenContract;

  IERC20 usdcToken;
  IERC20 sampleToken;

  uint256 rate;
  uint256 airdropAmount;
  uint256 proTier;
  uint256 midTier;
  uint256 baseTier;

  // need parameters around validity window of sale (start + end times). also should be able to be adjusted by owner

  // mapping for eligible airdrop recipients
  mapping (address => bool) private _hasClaimedAirdrop;

  // mapping for those who are entitled to purchasing tokens at a discount
  mapping (address => uint256) private _purchasedAmount;

  /*///////////////////////////////////////////////////////////////
                                ERRORS
  //////////////////////////////////////////////////////////////*/

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();

  /*///////////////////////////////////////////////////////////////
                                EVENTS
  //////////////////////////////////////////////////////////////*/

  event ClaimAirdrop(address indexed claimant, uint256 amount);
  event Purchase(address indexed claimaint, uint256 amount);
  event SetOwner(address indexed prevOwner, address indexed newOwner);
  event SetRate(address indexed owner, uint256 oldRate, uint256 newRate);
  event WithdrawAll(address indexed owner);
  event WithdrawToken(address indexed owner, address indexed token);

  /*///////////////////////////////////////////////////////////////
                              MODIFIERS
  //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(owner == msg.sender, "Function is only callable by the owner");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  // @dev assume we initialize this contract with arrays with addresses <> balances matched up at the same index,
  // though this may be costly
  constructor(bytes32 _merkleRoot, address _usdcTokenContract, address _sampleTokenContract) {
    owner = msg.sender;
    merkleRoot = _merkleRoot;

    usdcTokenContract = _usdcTokenContract;
    usdcToken = IERC20(_usdcTokenContract);
    sampleTokenContract = _sampleTokenContract;
    sampleToken = IERC20(_sampleTokenContract);

    // TODO: add getters/setters for all
    rate = 350; // # USDC required for 1 SAMP in base units
    airdropAmount = 1600000; // 160 SAMP
    proTier = 20000000; // 2000 SAMP
    midTier = 7000000; // 700 SAMP
    baseTier = 1000000; // 100 SAMP
  }

  /*///////////////////////////////////////////////////////////////
                    AIRDROP + PURCHASE FUNCTIONALITY
  //////////////////////////////////////////////////////////////*/

  // @dev Claim airdrop, only for those with > 2000 balance. 
  // Note: only claimable to msg.sender so that people can't claim airdrops on behalf of others
  // examples of how to do such crowdsales: https://docs.openzeppelin.com/contracts/2.x/crowdsales
  // @return success (bool)
  function claimAirdrop(uint256 snapshotAmount, bytes32[] memory proof) public returns (bool success){
    require(!checkAirdropClaimed(msg.sender), "Airdrop already claimed");
    require(_purchasedAmount[msg.sender] == 0, "You've begun purchasing tokens"); // this should not be possible, per logic
    require(verifyMerkleProof(msg.sender, snapshotAmount, proof), "Ineligible");

    _hasClaimedAirdrop[msg.sender] = true;
    sampleToken.safeTransfer(msg.sender, airdropAmount); // this should guard against the case where balance is insufficient

    emit ClaimAirdrop(msg.sender, airdropAmount);
    
    success = true;
  }

  // @dev Purchase SAMP tokens in exchange for USDC
  // purchasing tokens will require the user to approve the token (USDC) for spending with this dapp
  // @param amount (uint256): desired amount of SAMP, in base units
  // example: you want to buy 1600 SAMP at 3.50 USDC each. you transfer 1600 * 3.50 USDC, get back 1600 SAMP.
  function purchaseTokens(uint256 purchaseAmount, uint256 snapshotAmount, bytes32[] memory proof) public returns (bool success) {
    require(!checkAirdropClaimed(msg.sender), "Airdrop claimed. Ineligible for purchase");
    require(verifyMerkleProof(msg.sender, snapshotAmount, proof), "Ineligible");
    require(snapshotAmount >= baseTier, "Insufficient tokens to participate in purchase"); // 100 whole unit requirement
    require(snapshotAmount <= proTier, "Ineligible to participate in purchase. See airdrop instead"); // 2000 whole unit maximum

    uint256 allocation;
    uint256 usdcCost;

    if (snapshotAmount >= 3500000) { // < 2000 due to the above require case, >= 350 tokens
      // entitled to 2000 - amount
      allocation = remainingAllocation(msg.sender, snapshotAmount, proof);
      require(purchaseAmount <= allocation, "Attempting to buy more than allocation");

      usdcCost = purchaseAmount * rate;
      conductTrade(msg.sender, usdcCost, purchaseAmount);

    } else if (snapshotAmount >= baseTier) { // < 300, >= 100 tokens
      // entitled to 700 - amount
      allocation = remainingAllocation(msg.sender, snapshotAmount, proof);
      require(purchaseAmount <= allocation, "Attempting to buy more than allocation");

      usdcCost = purchaseAmount * rate;
      conductTrade(msg.sender, usdcCost, purchaseAmount);

    } else { // < 100 tokens
      // we shouldn't reach this case given we have that require statement above; ineligible to participate
    }

    emit Purchase(msg.sender, purchaseAmount);

    success = true;
  }

  // @dev Helper function that facilitates purchases + movement of funds
  // Note: purchasing tokens will require the user to approve the token (USDC) for spending with this dapp
  // @param buyer (address): address that will be spending USDC in exchange for SAMP
  // @param SAMPAmount (uint256): desired amount of SAMP, in base units
  // @param USDCAmount (uint256): USDC being spent, in base units
  // @return success (bool)
  function conductTrade(address buyer, uint256 USDCAmount, uint256 SAMPAmount) internal returns (bool success) {
    checkUSDCAllowance(buyer, USDCAmount);

    // send USDC tokens from buyer to contract  
    usdcToken.safeTransferFrom(buyer, address(this), USDCAmount);

    // send tokens from contract to buyer; maybe we can specify a separate recipient
    sampleToken.safeTransfer(buyer, SAMPAmount);

    // update state
    _purchasedAmount[buyer] += SAMPAmount;

    success = true;
  }

  /*///////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
                       (note owner == admin)
  //////////////////////////////////////////////////////////////*/


  // @dev Update the owner of the contract (admin only)
  // @param newOwner (address)
  function setOwner(address newOwner) onlyOwner external {
    // prevent accidentally making this contract inaccessible
    require(newOwner != address(0));
    // prevent unnecessary change
    require(newOwner != owner);

    emit SetOwner(owner, newOwner);

    owner = newOwner;
  }

  // @dev Update the exchange rate between USDC <> SAMP (admin only).
  // Note that this is in the form of USDC per SAMP in base units
  function setRate(uint256 usdcPerToken) onlyOwner external {
    require(usdcPerToken > 0, "Rejecting a 0 rate");

    emit SetRate(owner, rate, usdcPerToken);
  
    rate = usdcPerToken;
  }

  // @dev Withdraw allows admin to return all funds (USDC, SAMP, ETH) to admin address
  // @return success (bool)
  function withdrawAllTokens() onlyOwner public returns (bool success) {
    if (usdcToken.balanceOf(address(this)) > 0) {
      usdcToken.safeTransfer(owner, usdcToken.balanceOf(address(this)));
    }
    
    if (sampleToken.balanceOf(address(this)) > 0) {
      sampleToken.safeTransfer(owner, sampleToken.balanceOf(address(this)));
    }
    
    if (address(this).balance > 0) {
      payable(owner).transfer(address(this).balance);
    }

    emit WithdrawAll(owner);

    success = true;
  }

  // @dev Withdraw specific token contract to admin address
  // @return success (bool)
  function withdrawToken(address tokenAddress) onlyOwner public returns (bool success) {
    IERC20 token = IERC20(tokenAddress);
    if (token.balanceOf(address(this)) > 0) {
      token.safeTransfer(owner, token.balanceOf(address(this)));
    }

    emit WithdrawToken(owner, tokenAddress);

    success = true;
  } 

  /*///////////////////////////////////////////////////////////////
                        EXTERNAL GETTERS
  //////////////////////////////////////////////////////////////*/

  // @dev Fetch exchange rate between USDC <> SAMP (USDC per SAMP in base units)
  // @return uint256
  function getRate() view external returns (uint256) {
    return rate;
  }

  // @dev Check if participant has claimed airdrop
  // @param participant (address)
  // @return bool
  function checkAirdropClaimed(address participant) public view returns (bool) {
    return _hasClaimedAirdrop[participant];
  }

  // 
  // @dev Check if participant is eligible to claim airdrop
  // @param participant (address)
  // @return bool
  function checkAirdropEligibility(address participant, uint256 amount, bytes32[] memory proof) public view returns (bool) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    return amount >= proTier;
  }
  
  // @dev Check if participant is eligible for discounted token sale
  // @param participant (address)
  // @return bool
  function checkPurchaseEligibility(address participant, uint256 amount, bytes32[] memory proof) public view returns (bool) {
    return initialAllocation(participant, amount, proof) > 0;
  }

  // @dev Public function that returns the total initial purchase allocation for participant.
  // Allocation is dependent upon initial snapshot values, which are determined at deployment time.
  // @param participant (address) 
  // @return allocation (uint256)
  function initialAllocation(address participant, uint256 amount, bytes32[] memory proof) public view returns (uint256 allocation) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    if (amount > proTier) { // > 2000
      // no allocation; eligible for airdrop instead
      allocation = 0;

    } else if (amount >= 3500000) { // <= 2000, >= 350 tokens
      // entitled to 2000 - amount
      allocation = proTier - amount;

    } else if (amount >= baseTier) { // < 300, >= 100 tokens
      // entitled to 700 - amount
      allocation = midTier - amount;

    } else { // < 100 tokens
      allocation = 0; // we can also return -1 if that better indicates that the address wasn't eligible in the first place (insufficienrt funds)
    }
  }

  // @dev Public function that returns the purchased allocation for participant.
  // @param participant (address) 
  // @return allocation (uint256)
  function purchasedAllocation(address participant) public view returns (uint256 purchasedAmount) {
    purchasedAmount = _purchasedAmount[participant];
  }

  // @dev Public function that returns the remaining allocation for participant.
  // Remaining allocation is dependent upon initial snapshot values, user tier, and amount already claimed.
  // @param participant (address) 
  // @return allocation (uint256)
  function remainingAllocation(address participant, uint256 amount, bytes32[] memory proof) public view returns (uint256 allocation) {
    require(verifyMerkleProof(participant, amount, proof), "Ineligible");

    uint256 purchasedAmount = _purchasedAmount[participant];

    uint256 initial = initialAllocation(participant, amount, proof);

    allocation = initial - purchasedAmount; // should never be negative
  }

  /*///////////////////////////////////////////////////////////////
                            HELPERS
  //////////////////////////////////////////////////////////////*/

  // @dev Helper function that ensures USDC spend allowance by this contract is sufficient
  // @param _participant (address): spender
  // @param _amount (uint256): amount to be spent
  // @return allowed (bool)
  function checkUSDCAllowance(address _participant, uint256 _amount) internal view returns (bool allowed) {
    uint256 allowance = usdcToken.allowance(_participant, address(this));
    require(allowance >= _amount, "Insufficient token allowance");

    allowed = true;
  }

  function verifyMerkleProof(address _address, uint256 _amount, bytes32[] memory _proof) internal view returns (bool valid) {
    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(_address, _amount));
    bool isValidLeaf = MerkleProof.verify(_proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    valid = true;
  }

  /*///////////////////////////////////////////////////////////////
                            FALLBACK
  //////////////////////////////////////////////////////////////*/

  fallback() external payable {}
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
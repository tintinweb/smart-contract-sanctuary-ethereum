// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./utils/ContractGuard.sol";
import "./ValidatorAssetManager.sol";
import "./ValidatorRewardManager.sol";
import "./ValidatorConditionChecker.sol";

contract PodValidator is ContractGuard, ERC721Holder, ERC1155Holder {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public operator;
  IERC20 public paw;
  IERC20 public pod;
  ValidatorAssetManager public assetManager;
  ValidatorRewardManager public rewardManager;
  ValidatorConditionChecker public conditionChecker;

  struct Validator {
    string name;
    uint256 taxPercent; // 0 - 9999
    bool inStaking;
  }

  uint256 public validatorsCount;
  mapping(address => uint256) public validatorIndexByOwner;
  mapping(uint256 => Validator) public validators;

  constructor(IERC20 _paw, IERC20 _pod) {
    paw = _paw;
    pod = _pod;
    operator = msg.sender;
  }

  /* ========== Event =============== */
  event RewardPaid(
    address indexed user,
    address indexed validator,
    uint256 reward,
    uint256 taxAmount
  );
  event StakedNFT(
    address indexed user,
    address indexed validator,
    address indexed nft,
    uint256 tokenId,
    uint256 amount
  );
  event StakedPod(address indexed user, address indexed validator, uint256 amount);

  event UnstakedNFT(
    address indexed user,
    address indexed validator,
    address indexed nft,
    uint256 tokenId,
    uint256 amount
  );

  event UnstakedPod(address indexed user, address indexed validator, uint256 amount);

  event ValidatorSubmitted(address indexed user);

  /* ========== Modifiers =============== */
  modifier onlyOperator() {
    require(msg.sender == operator, "only operator");
    _;
  }

  modifier validatorExist(address _validatorAddress) {
    require(validatorIndexByOwner[_validatorAddress] != 0, "PodValidator: validator not exist");
    _;
  }

  modifier onlyValidNft(address _nftAddress) {
    require(assetManager.isValidNft(_nftAddress), "PodValidator: invalid nft address");
    _;
  }

  modifier onlyStakedNftOwner(
    address _validatorAddress,
    address _nftAddress,
    uint256 _tokenId,
    uint256 _amount
  ) {
    require(
      assetManager.isOwnedNft(_validatorAddress, _nftAddress, msg.sender, _tokenId, _amount),
      "nft not staked"
    );
    _;
  }

  modifier isStakedPodAtLeast(address _validatorAddress, uint256 _amount) {
    require(
      assetManager.isStakedPodAtLeast(_validatorAddress, msg.sender, _amount),
      "not enough staked pod amount"
    );
    _;
  }

  modifier claimReward(address _validatorAddress) {
    if (assetManager.isValidatorStaked(_validatorAddress)) {
      uint256 reward = rewardManager.claimRewardHolder(_validatorAddress, msg.sender);
      if (reward > 0) {
        uint256 taxPercent = validators[validatorIndexByOwner[_validatorAddress]].taxPercent;
        uint256 tax = (reward * taxPercent) / 10000;
        if (tax > 0 && msg.sender != _validatorAddress) {
          reward = reward - tax;
          paw.safeTransfer(_validatorAddress, tax);
        } else {
          tax = 0;
        }

        paw.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, _validatorAddress, reward, tax);
      }
    }
    _;
  }

  // ===== GOVERNANCE =====
  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setAssetManager(address _assetManager) public onlyOperator {
    assetManager = ValidatorAssetManager(_assetManager);
  }

  function setRewardManager(address _rewardManager) public onlyOperator {
    rewardManager = ValidatorRewardManager(_rewardManager);
  }

  function setValidatorConditionChecker(address _conditionChecker) public onlyOperator {
    conditionChecker = ValidatorConditionChecker(_conditionChecker);
  }

  function allocateSeigniorage(uint256 _amount) public onlyOperator {
    paw.safeTransferFrom(msg.sender, address(this), _amount);
    rewardManager.allocateSeigniorage(msg.sender, _amount);
  }

  function setWealthDecider(address _nftAddress, address _wealthDecider) public onlyOperator {
    assetManager.setWealthDecider(_nftAddress, _wealthDecider);
  }

  function setConditionToSubmitByNft(address _nftAddress, uint256 _nftRequiredAmount)
    public
    onlyOperator
  {
    conditionChecker.setConditionToSubmitByNft(_nftAddress, _nftRequiredAmount);
  }

  // ===== VALIDATOR VIEW =====
  function stakeRequiredNft(address _nftAddress, uint256 _tokenId) public onlyValidNft(_nftAddress) {
    // ignore validator from stake required nft if validator is submitted to prevent unexpected wealth change happened
    require(validatorIndexByOwner[msg.sender] == 0, "PodValidator: already staked");
    IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

    assetManager.updateHolderNftStakedAmountByTokenId(
      msg.sender,
      msg.sender,
      _nftAddress,
      _tokenId,
      1,
      false
    );

    assetManager.updateStakedInfo(
      msg.sender,
      msg.sender,
      assetManager.wealthCalcNft(_nftAddress, _tokenId, 1),
      1,
      0,
      false
    );
  }

  function withdrawnRequiredNft(address _nftAddress, uint256 _tokenId)
    public
    onlyStakedNftOwner(msg.sender, _nftAddress, _tokenId, 1)
  {
    // ignore validator from unstake required nft if validator is submitted to prevent unexpected wealth change happened
    require(validatorIndexByOwner[msg.sender] == 0, "PodValidator: already staked");

    IERC721(_nftAddress).transferFrom(address(this), msg.sender, _tokenId);

    assetManager.updateHolderNftStakedAmountByTokenId(
      msg.sender,
      msg.sender,
      _nftAddress,
      _tokenId,
      1,
      true
    );

    assetManager.updateStakedInfo(
      msg.sender,
      msg.sender,
      assetManager.wealthCalcNft(_nftAddress, _tokenId, 1),
      1,
      0,
      true
    );
  }

  function submitValidator(
    string calldata _name,
    uint256 _taxPercent // 0 - 9999 (0 - 99,99%)
  ) public {
    require(validatorIndexByOwner[msg.sender] == 0, "PodValidator: already staked");
    require(_taxPercent < 10000, "PodValidator: invalid tax percent");
    require(
      conditionChecker.isValidatorValidForSubmit(msg.sender),
      "not reach condition to submit become validator"
    );

    validatorsCount += 1;
    Validator memory _validator = Validator({
      name: _name,
      taxPercent: _taxPercent,
      inStaking: true
    });

    validators[validatorsCount] = _validator;
    validatorIndexByOwner[msg.sender] = validatorsCount;

    assetManager.setValidatorValidForStake(msg.sender);
    rewardManager.setupBootstrapHisotryForValidator(msg.sender);

    emit ValidatorSubmitted(msg.sender);
  }

  function validatorDetail(address _validatorAddress)
    public
    view
    returns (
      string memory name,
      uint256 taxPercent,
      bool eligible,
      bool inStaking
    )
  {
    Validator memory _validator = validators[validatorIndexByOwner[_validatorAddress]];
    name = _validator.name;
    taxPercent = _validator.taxPercent;
    eligible = conditionChecker.isValidatorValidForSubmit(msg.sender);
    inStaking = _validator.inStaking;
  }

  // ===== USER VIEW =====
  function stakedAmountNft(address _validatorAddress, address _nftAddress)
    public
    view
    returns (uint256)
  {
    return assetManager.getNftStakedByHolder(_validatorAddress, msg.sender, _nftAddress);
  }

  function stakedAmountPod(address _validatorAddress) public view returns (uint256) {
    return assetManager.getPodStakedByHolder(_validatorAddress, msg.sender);
  }

  function stakePod(address _validatorAddress, uint256 _amount)
    public
    validatorExist(_validatorAddress)
    claimReward(_validatorAddress)
  {
    pod.transferFrom(msg.sender, address(this), _amount);

    assetManager.updatePodStakedAmount(_validatorAddress, msg.sender, _amount, false);

    assetManager.updateStakedInfo(
      _validatorAddress,
      msg.sender,
      assetManager.wealthCalcPod(_amount),
      0,
      _amount,
      false
    );

    emit StakedPod(msg.sender, _validatorAddress, _amount);
  }

  function widthdrawnPod(address _validatorAddress, uint256 _amount)
    public
    isStakedPodAtLeast(_validatorAddress, _amount)
    validatorExist(_validatorAddress)
    claimReward(_validatorAddress)
  {
    pod.transfer(msg.sender, _amount);

    assetManager.updatePodStakedAmount(_validatorAddress, msg.sender, _amount, true);

    assetManager.updateStakedInfo(
      _validatorAddress,
      msg.sender,
      assetManager.wealthCalcPod(_amount),
      0,
      _amount,
      true
    );

    emit UnstakedPod(msg.sender, _validatorAddress, _amount);
  }

  function stakeNFT(
    address _validatorAddress,
    address _nft,
    uint256 _tokenId,
    uint256 _amount
  ) public onlyValidNft(_nft) validatorExist(_validatorAddress) claimReward(_validatorAddress) {
    if (assetManager.isNft721(_nft)) {
      require(_amount == 1, "invalid amount");
      IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);
    } else {
      IERC1155(_nft).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "0x0");
    }

    assetManager.updateHolderNftStakedAmountByTokenId(
      _validatorAddress,
      msg.sender,
      _nft,
      _tokenId,
      _amount,
      false
    );

    assetManager.updateStakedInfo(
      _validatorAddress,
      msg.sender,
      assetManager.wealthCalcNft(_nft, _tokenId, _amount),
      _amount,
      0,
      false
    );

    emit StakedNFT(msg.sender, _validatorAddress, _nft, _tokenId, _amount);
  }

  function withdrawnNFT(
    address _validatorAddress,
    address _nft,
    uint256 _tokenId,
    uint256 _amount
  )
    public
    validatorExist(_validatorAddress)
    onlyStakedNftOwner(_validatorAddress, _nft, _tokenId, _amount)
    claimReward(_validatorAddress)
  {
    if (assetManager.isNft721(_nft)) {
      require(_amount == 1, "invalid amount");
      IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
    } else {
      IERC1155(_nft).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0x1");
    }

    assetManager.updateHolderNftStakedAmountByTokenId(
      _validatorAddress,
      msg.sender,
      _nft,
      _tokenId,
      1,
      true
    );

    assetManager.updateStakedInfo(
      _validatorAddress,
      msg.sender,
      assetManager.wealthCalcNft(_nft, _tokenId, 1),
      1,
      0,
      true
    );

    emit UnstakedNFT(msg.sender, _validatorAddress, _nft, _tokenId, _amount);
  }

  function batchWithdrawnNFT(
    address _validatorAddress,
    address _nft,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) public {
    require(_tokenIds.length == _amounts.length, "invalid tokenIds, amounts input");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      withdrawnNFT(_validatorAddress, _nft, _tokenIds[i], _amounts[i]);
    }
  }

  function rewardEarnedByValidator(address _validatorAddress)
    public
    view
    validatorExist(_validatorAddress)
    returns (uint256)
  {
    return rewardManager.estimateHolderEarned(_validatorAddress, msg.sender);
  }

  function claimRewardByValidator(address _validatorAddress)
    public
    validatorExist(_validatorAddress)
    claimReward(_validatorAddress)
  {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        // solhint-disable-next-line avoid-tx-origin
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            "ContractGuard: one block, one function"
        );
        require(
            !checkSameSenderReentranted(),
            "ContractGuard: one block, one function"
        );

        _;

        // solhint-disable-next-line avoid-tx-origin
        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/INftRarityDecider.sol";

contract ValidatorAssetManager {
  struct Validator {
    bool staked;
    uint256 nftCount;
    uint256 pod;
    uint256 wealth;
  }

  // INIT
  mapping(address => address) public wealthDecider;
  address public rootContract;
  uint256 public constant POD_WEALTH_RATIO = 1;

  // STATE
  mapping(address => uint256) private validatorWealth;
  mapping(address => mapping(address => uint256)) private holderWealthByValidator;
  uint256 public stakedWealth;

  mapping(bytes32 => uint256) private holderNftStakedAmountByTokenId;
  mapping(bytes32 => uint256) private holderNftStakedAmount;
  mapping(bytes32 => uint256) private holderPodStakedAmount;
  mapping(address => Validator) public validatorStakedInfo;

  modifier onlyRootContract() {
    require(msg.sender == rootContract, "can only call from root contract");
    _;
  }

  constructor(address _rootContract) {
    stakedWealth = 0;
    rootContract = _rootContract;
  }

  // --- GET ---
  function isValidatorStaked(address _validatorAddress) public view returns (bool) {
    return validatorStakedInfo[_validatorAddress].staked;
  }

  function getValidatorWealth(address _validatorAddress) public view returns (uint256) {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    if (!_validator.staked || _validator.pod == 0) {
      return 0;
    }

    return _validator.wealth;
  }

  function getHolderWealth(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    return holderWealthByValidator[_validatorAddress][_holderAddress];
  }

  function isValidNft(address _nftAddress) public view returns (bool) {
    return wealthDecider[_nftAddress] != address(0);
  }

  function wealthCalcNft(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _amount
  ) public view returns (uint256) {
    if (wealthDecider[_nftAddress] == address(0)) {
      return 0;
    }

    return INftRarityDecider(wealthDecider[_nftAddress]).calcRarity(_tokenId) * _amount;
  }

  function wealthCalcPod(uint256 _amount) public pure returns (uint256) {
    return _amount * POD_WEALTH_RATIO;
  }

  function _nftHolderHash(
    address _validatorAddress,
    address _owner,
    address _nft
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_validatorAddress, _owner, _nft));
  }

  function _nftTokenHolderHash(
    address _validatorAddress,
    address _owner,
    address _nft,
    uint256 _tokenId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_validatorAddress, _owner, _nft, _tokenId));
  }

  function _podHolderHash(address _validatorAddress, address _owner)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_validatorAddress, _owner));
  }

  function isOwnedNft(
    address _validatorAddress,
    address _nftAddress,
    address _holderAddress,
    uint256 _tokenId,
    uint256 _amount
  ) public view returns (bool) {
    bytes32 _nftHash = _nftTokenHolderHash(
      _validatorAddress,
      _holderAddress,
      _nftAddress,
      _tokenId
    );
    return holderNftStakedAmountByTokenId[_nftHash] >= _amount;
  }

  function isStakedPodAtLeast(
    address _validatorAddress,
    address _holderAddress,
    uint256 _amount
  ) public view returns (bool) {
    bytes32 _podHash = _podHolderHash(_validatorAddress, _holderAddress);
    return holderPodStakedAmount[_podHash] >= _amount;
  }

  function getNftStakedByHolder(
    address _validatorAddress,
    address _holderAddress,
    address _nftAddress
  ) public view returns (uint256) {
    bytes32 _nftHolder = _nftHolderHash(_validatorAddress, _holderAddress, _nftAddress);
    return holderNftStakedAmount[_nftHolder];
  }

  function getPodStakedByHolder(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    bytes32 _nftHolder = _podHolderHash(_validatorAddress, _holderAddress);
    return holderPodStakedAmount[_nftHolder];
  }

  function isNft721(address _nftAddress) public view returns (bool) {
    return INftRarityDecider(wealthDecider[_nftAddress]).isErc721();
  }

  // --- MUTATION ---
  function setValidatorValidForStake(address _validatorAddress) public onlyRootContract {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    if (_validator.staked) {
      return;
    }

    _validator.staked = true;
    validatorStakedInfo[_validatorAddress] = _validator;

    stakedWealth += _validator.wealth;
  }

  function setStakedWealth(uint256 newWealth) public onlyRootContract {
    stakedWealth = newWealth;
  }

  function updateValidatorWealth(address _validatorAddress, uint256 newWealth)
    public
    onlyRootContract
  {
    validatorWealth[_validatorAddress] = newWealth;
  }

  function updateHolderWealth(
    address _validatorAddress,
    address _holderAddress,
    uint256 newWealth
  ) public onlyRootContract {
    holderWealthByValidator[_validatorAddress][_holderAddress] = newWealth;
  }

  function setWealthDecider(address _nftAddress, address _wealthDecider) public onlyRootContract {
    wealthDecider[_nftAddress] = _wealthDecider;
  }

  function updatePodStakedAmount(
    address _validatorAddress,
    address _holderAddress,
    uint256 _amount,
    bool _isReduce
  ) public onlyRootContract {
    bytes32 _podHash = _podHolderHash(_validatorAddress, _holderAddress);
    if (_isReduce) {
      holderPodStakedAmount[_podHash] -= _amount;
    } else {
      holderPodStakedAmount[_podHash] += _amount;
    }
  }

  function updateHolderNftStakedAmountByTokenId(
    address _validatorAddress,
    address _holderAddress,
    address _nftAddress,
    uint256 _tokenId,
    uint256 _amount,
    bool _isReduce
  ) public onlyRootContract {
    bytes32 _nftTokenIdHolderHash = _nftTokenHolderHash(
      _validatorAddress,
      _holderAddress,
      _nftAddress,
      _tokenId
    );
    bytes32 _nftHolder = _nftHolderHash(_validatorAddress, _holderAddress, _nftAddress);

    if (_isReduce) {
      holderNftStakedAmountByTokenId[_nftTokenIdHolderHash] -= _amount;
      holderNftStakedAmount[_nftHolder] -= _amount;
    } else {
      holderNftStakedAmountByTokenId[_nftTokenIdHolderHash] += _amount;
      holderNftStakedAmount[_nftHolder] += _amount;
    }
  }

  function updateStakedInfo(
    address _validatorAddress,
    address _holderAddress,
    uint256 _wealthChange,
    uint256 _nftStakedChange,
    uint256 _podChange,
    bool _isReduce
  ) public onlyRootContract {
    Validator memory _validator = validatorStakedInfo[_validatorAddress];
    uint256 wealthBefore = _validator.wealth;
    if (_isReduce) {
      _validator.nftCount = _validator.nftCount - _nftStakedChange;
      _validator.pod = _validator.pod - _podChange;
      _validator.wealth = _validator.wealth - _wealthChange;
      holderWealthByValidator[_validatorAddress][_holderAddress] -= _wealthChange;
    } else {
      _validator.nftCount = _validator.nftCount + _nftStakedChange;
      _validator.pod = _validator.pod + _podChange;
      _validator.wealth = _validator.wealth + _wealthChange;
      holderWealthByValidator[_validatorAddress][_holderAddress] += _wealthChange;
    }

    // update staked wealth
    if (_validator.staked) {
      stakedWealth = stakedWealth - wealthBefore + _validator.wealth;
    }

    validatorStakedInfo[_validatorAddress] = _validator;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/ContractGuard.sol";
import "./interfaces/ITreasury.sol";
import "./ValidatorAssetManager.sol";

contract ValidatorRewardManager is ContractGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  ITreasury public treasury;
  address public rootContract;
  ValidatorAssetManager public assetManager;

  struct ValidatorRewardInfo {
    uint256 lastSnapshotIndex;
    uint256 rewardEarned;
    uint256 epochTimerStart;
    uint256 holdAmount;
  }

  struct HolderRewardInfo {
    uint256 lastSnapshotIndex;
    uint256 rewardEarned;
    uint256 epochTimerStart;
  }

  struct RewardSnapshot {
    uint256 time;
    uint256 rewardReceived;
    uint256 rewardPerShare;
  }

  // reward handle stuff
  uint256 public withdrawLockupEpochs;
  uint256 public rewardLockupEpochs;

  RewardSnapshot[] public rewardPoolHistory; // reward history for all validator
  mapping(address => RewardSnapshot[]) public rewardHistoryHolderByValidator; // reward history for all holder of 1 validator

  mapping(address => ValidatorRewardInfo) public validatorRewardInfo;
  mapping(address => mapping(address => HolderRewardInfo)) public holderRewardInfoByValidator;

  // EVENTS
  event RewardPoolAdded(address indexed user, uint256 reward);

  modifier onlyRootContract() {
    require(msg.sender == rootContract, "can only call from root contract");
    _;
  }

  function updateRewardForValidator(address _validatorAddress) internal {
    if (_validatorAddress != address(0)) {
      ValidatorRewardInfo memory _validator = validatorRewardInfo[_validatorAddress];
      _validator.rewardEarned = earnedValidator(_validatorAddress);
      _validator.lastSnapshotIndex = latestRewardPoolSnapshotIndex();
      validatorRewardInfo[_validatorAddress] = _validator;
    }
  }

  function updateRewardForHolderByValidator(address _validatorAddress, address _holderAddress)
    internal
  {
    if (_holderAddress != address(0) && _validatorAddress != address(0)) {
      HolderRewardInfo memory rewardInfo = holderRewardInfoByValidator[_validatorAddress][
        _holderAddress
      ];
      rewardInfo.rewardEarned = holderEarnedByValidator(_validatorAddress, _holderAddress);
      rewardInfo.lastSnapshotIndex = latestHolderSnapshotIndexByValidator(_validatorAddress);
      holderRewardInfoByValidator[_validatorAddress][_holderAddress] = rewardInfo;
    }
  }

  function estimateHolderEarned(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    uint256 _validatorEarned = earnedValidator(_validatorAddress);
    if (_validatorEarned == 0) {
      return holderEarnedByValidator(_validatorAddress, _holderAddress);
    }

    uint256 storedRPS = getLastSnapshotOfHolder(_validatorAddress, _holderAddress).rewardPerShare;
    uint256 prevRPS = getLatestSnapshotOfValidator(_validatorAddress).rewardPerShare;
    uint256 latestRPS = prevRPS.add(
      _validatorEarned.mul(1e18).div(assetManager.getValidatorWealth(_validatorAddress))
    );

    return
      assetManager
        .getHolderWealth(_validatorAddress, _holderAddress)
        .mul(latestRPS.sub(storedRPS))
        .div(1e18)
        .add(holderRewardInfoByValidator[_validatorAddress][_holderAddress].rewardEarned);
  }

  function holderEarnedByValidator(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    uint256 latestRPS = getLatestSnapshotOfValidator(_validatorAddress).rewardPerShare;
    uint256 storedRPS = getLastSnapshotOfHolder(_validatorAddress, _holderAddress).rewardPerShare;

    return
      assetManager
        .getHolderWealth(_validatorAddress, _holderAddress)
        .mul(latestRPS.sub(storedRPS))
        .div(1e18)
        .add(holderRewardInfoByValidator[_validatorAddress][_holderAddress].rewardEarned);
  }

  function getLastSnapshotOfHolder(address _validatorAddress, address _holderAddress)
    internal
    view
    returns (RewardSnapshot memory)
  {
    return
      rewardHistoryHolderByValidator[_validatorAddress][
        getLastSnapshotHolderIndexOf(_validatorAddress, _holderAddress)
      ];
  }

  function getLastSnapshotHolderIndexOf(address _validatorAddress, address _holderAddress)
    public
    view
    returns (uint256)
  {
    return holderRewardInfoByValidator[_validatorAddress][_holderAddress].lastSnapshotIndex;
  }

  function getLatestSnapshotOfValidator(address _validatorAddress)
    internal
    view
    returns (RewardSnapshot memory)
  {
    return
      rewardHistoryHolderByValidator[_validatorAddress][
        latestHolderSnapshotIndexByValidator(_validatorAddress)
      ];
  }

  function latestHolderSnapshotIndexByValidator(address _validatorAddress)
    public
    view
    returns (uint256)
  {
    return rewardHistoryHolderByValidator[_validatorAddress].length.sub(1);
  }

  constructor(
    ValidatorAssetManager _assetManager,
    address _rootContract,
    address _treasuryContract
  ) {
    assetManager = _assetManager;
    rootContract = _rootContract;
    treasury = ITreasury(_treasuryContract);

    RewardSnapshot memory genesisSnapshot = RewardSnapshot({
      time: block.number,
      rewardReceived: 0,
      rewardPerShare: 0
    });
    rewardPoolHistory.push(genesisSnapshot);

    withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
    rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward
  }

  function earnedValidator(address _validatorAddress) public view returns (uint256) {
    uint256 latestRPS = getLatestRewardPoolSnapshot().rewardPerShare;
    uint256 storedRPS = getLastValidatorRewardSnapshot(_validatorAddress).rewardPerShare;

    return
      assetManager
        .getValidatorWealth(_validatorAddress)
        .mul(latestRPS.sub(storedRPS))
        .div(1e18)
        .add(validatorRewardInfo[_validatorAddress].rewardEarned);
  }

  function getLatestRewardPoolSnapshot() internal view returns (RewardSnapshot memory) {
    return rewardPoolHistory[latestRewardPoolSnapshotIndex()];
  }

  function latestRewardPoolSnapshotIndex() public view returns (uint256) {
    return rewardPoolHistory.length.sub(1);
  }

  function getLastValidatorRewardSnapshot(address _validatorAddress)
    internal
    view
    returns (RewardSnapshot memory)
  {
    return rewardPoolHistory[getLastValidatorRewardSnapshotIndex(_validatorAddress)];
  }

  function getLastValidatorRewardSnapshotIndex(address _validatorAddress)
    public
    view
    returns (uint256)
  {
    return validatorRewardInfo[_validatorAddress].lastSnapshotIndex;
  }

  function setupBootstrapHisotryForValidator(address _validatorAddress) public onlyRootContract {
    RewardSnapshot memory genesisSnapshot = RewardSnapshot({
      time: block.number,
      rewardReceived: 0,
      rewardPerShare: 0
    });
    rewardHistoryHolderByValidator[_validatorAddress].push(genesisSnapshot);
  }

  function allocateSeigniorage(address _sender, uint256 _amount)
    external
    onlyOneBlock
    onlyRootContract
  {
    require(_amount > 0, "Masonry: Cannot allocate 0");
    require(assetManager.stakedWealth() > 0, "Masonry: Cannot allocate when totalSupply is 0");

    // Create & add new snapshot
    uint256 prevRPS = getLatestRewardPoolSnapshot().rewardPerShare;
    uint256 nextRPS = prevRPS.add(_amount.mul(1e18).div(assetManager.stakedWealth()));

    RewardSnapshot memory newSnapshot = RewardSnapshot({
      time: block.number,
      rewardReceived: _amount,
      rewardPerShare: nextRPS
    });
    rewardPoolHistory.push(newSnapshot);

    emit RewardPoolAdded(_sender, _amount);
  }

  function claimRewardValidator(address _validatorAddress) public {
    updateRewardForValidator(_validatorAddress);

    uint256 reward = validatorRewardInfo[_validatorAddress].rewardEarned;
    if (reward > 0) {
      require(
        validatorRewardInfo[_validatorAddress].epochTimerStart.add(rewardLockupEpochs) <=
          treasury.epoch(),
        "Masonry: still in reward lockup"
      );
      validatorRewardInfo[_validatorAddress].epochTimerStart = treasury.epoch(); // reset timer
      validatorRewardInfo[_validatorAddress].rewardEarned = 0;
      validatorRewardInfo[_validatorAddress].holdAmount =
        validatorRewardInfo[_validatorAddress].holdAmount +
        reward;

      uint256 prevRPS = getLatestSnapshotOfValidator(_validatorAddress).rewardPerShare;
      uint256 nextRPS = prevRPS.add(
        reward.mul(1e18).div(assetManager.getValidatorWealth(_validatorAddress))
      );

      // update reward holder
      RewardSnapshot memory newSnapshot = RewardSnapshot({
        time: block.number,
        rewardReceived: reward,
        rewardPerShare: nextRPS
      });

      rewardHistoryHolderByValidator[_validatorAddress].push(newSnapshot);
    }
  }

  function claimRewardHolder(address _validatorAddress, address _holderAddress)
    public
    returns (uint256)
  {
    claimRewardValidator(_validatorAddress);
    updateRewardForHolderByValidator(_validatorAddress, _holderAddress);
    uint256 reward = holderRewardInfoByValidator[_validatorAddress][_holderAddress].rewardEarned;
    if (reward > 0) {
      require(
        holderRewardInfoByValidator[_validatorAddress][_holderAddress].epochTimerStart.add(
          rewardLockupEpochs
        ) <= treasury.epoch(),
        "Validator: still in reward lockup"
      );
      holderRewardInfoByValidator[_validatorAddress][_holderAddress].epochTimerStart = treasury
        .epoch(); // reset timer
      holderRewardInfoByValidator[_validatorAddress][_holderAddress].rewardEarned = 0;
    }
    return reward;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ValidatorAssetManager.sol";

contract ValidatorConditionChecker {
  address public operator;
  address public rootContract;
  address[] public requiredNft;
  ValidatorAssetManager public assetManager;

  struct Condition {
    address requiredNft;
    uint256 requiredNftAmount;
  }

  mapping(uint256 => Condition) private conditionsToSubmit;
  uint256 private conditionsToSubmitIndex;

  modifier onlyRootContract() {
    require(msg.sender == rootContract, "can only call from root contract");
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == rootContract, "only operator");
    _;
  }

  constructor(address _rootContract, address _assetManager) {
    operator = msg.sender;
    rootContract = _rootContract;
    assetManager = ValidatorAssetManager(_assetManager);
  }

  function setConditionToSubmitByNft(address _requiredNft, uint256 _nftRequiredAmount)
    public
    onlyOperator
  {
    Condition memory _condition = Condition({
      requiredNft: _requiredNft,
      requiredNftAmount: _nftRequiredAmount
    });
    conditionsToSubmit[conditionsToSubmitIndex] = _condition;
    conditionsToSubmitIndex = conditionsToSubmitIndex + 1;
  }

  function isValidatorValidForSubmit(address _validatorAddress) public view returns (bool) {
    for (uint256 i = 0; i < conditionsToSubmitIndex; i++) {
      Condition memory _condition = conditionsToSubmit[i];
      if (_condition.requiredNft != address(0)) {
        uint256 amount = assetManager.getNftStakedByHolder(
          _validatorAddress,
          _validatorAddress,
          _condition.requiredNft
        );
        if (_condition.requiredNftAmount > amount) {
          return false;
        }
      }
    }

    return true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INftRarityDecider {
  function calcRarity(uint256 _tokenId) external pure returns (uint256);
  function isErc721() external pure returns (bool);
  function isErc1155() external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
  function epoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function getPawPrice() external view returns (uint256);

  function buyBones(uint256 amount, uint256 targetPrice) external;

  function redeemBones(uint256 amount, uint256 targetPrice) external;
}
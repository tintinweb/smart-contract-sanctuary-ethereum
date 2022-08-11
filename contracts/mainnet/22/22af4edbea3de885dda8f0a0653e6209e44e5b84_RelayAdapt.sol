// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IWBase } from "./IWBase.sol";
import { RailgunLogic, Transaction, CommitmentPreimage, TokenData, TokenType } from "../../logic/RailgunLogic.sol";

/**
 * @title Relay Adapt
 * @author Railgun Contributors
 * @notice Multicall adapt contract for Railgun with relayer support
 */

contract RelayAdapt {
  using SafeERC20 for IERC20;

  // Snark bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
  // Use 0x000000000000000000000000000000000000dEaD as an alternative
  address constant public VERIFICATION_BYPASS = 0x000000000000000000000000000000000000dEaD;

  struct Call {
    address to;
    bytes data;
    uint256 value;
  }

  struct Result {
    bool success;
    string returnData;
  }

  event CallResult(Result[] callResults);

  // External contract addresses
  RailgunLogic public railgun;
  IWBase public wbase;

  /**
   * @notice only allows self calls to these contracts
   */
  modifier onlySelf() {
    require(msg.sender == address(this), "RelayAdapt: External call to onlySelf function");
    _;
  }

  /**
   * @notice Sets Railgun contract and wbase address
   */
  constructor(RailgunLogic _railgun, IWBase _wbase) {
    railgun = _railgun;
    wbase = _wbase;
  }

  /**
   * @notice Gets adapt params for Railgun batch
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _additionalData - Additional data
   * @return adapt params
   */
  function getAdaptParams(
    Transaction[] calldata _transactions,
    bytes memory _additionalData
  ) public pure returns (bytes32) {
    uint256[] memory firstNullifiers = new uint256[](_transactions.length);

    for (uint256 i = 0; i < _transactions.length; i++) {
      // Only need first nullifier
      firstNullifiers[i] = _transactions[i].nullifiers[0];
    }

    return keccak256(
      abi.encode(
        firstNullifiers,
        _transactions.length,
        _additionalData
      )
    );
  }

  /**
   * @notice Executes a batch of Railgun transactions
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _additionalData - Additional data
   * Should be random value if called directly
   * If called via multicall sub-call this can be extracted and submitted standalone
   * Be aware of the dangers of this before doing so!
   */
  function railgunBatch(
    Transaction[] calldata _transactions,
    bytes memory _additionalData
  ) public {
    bytes32 expectedAdaptParameters = getAdaptParams(_transactions, _additionalData);

    // Loop through each transaction and ensure adaptID parameters match
    for(uint256 i = 0; i < _transactions.length; i++) {
      require(
        _transactions[i].boundParams.adaptParams == expectedAdaptParameters
        // solhint-disable-next-line avoid-tx-origin
        || tx.origin == VERIFICATION_BYPASS,
        "GeneralAdapt: AdaptID Parameters Mismatch"
      );
    }

    // Execute railgun transactions
    railgun.transact(_transactions);
  }

  /**
   * @notice Executes a batch of Railgun deposits
   * @param _deposits - Tokens to deposit
   * @param _encryptedRandom - Encrypted random value for deposits
   * @param _npk - note public key to deposit to
   */
  function deposit(
    TokenData[] calldata _deposits,
    uint256[2] calldata _encryptedRandom,
    uint256 _npk
  ) external onlySelf {
    // Loop through each token specified for deposit and deposit our total balance
    // Due to a quirk with the USDT token contract this will fail if it's approval is
    // non-0 (https://github.com/Uniswap/interface/issues/1034), to ensure that your
    // transaction always succeeds when dealing with USDT/similar tokens make sure the last
    // call in your calls is a call to the token contract with an approval of 0
    CommitmentPreimage[] memory commitmentPreimages = new CommitmentPreimage[](_deposits.length);
    uint256 numValidTokens = 0;

    for (uint256 i = 0; i < _deposits.length; i++) {
      if (_deposits[i].tokenType == TokenType.ERC20) {
        IERC20 token = IERC20(_deposits[i].tokenAddress);

        // Fetch balance
        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
          numValidTokens += 1;

          // Approve the balance for deposit
          token.safeApprove(
            address(railgun),
            balance
          );

          // Push to deposits arrays
          commitmentPreimages[i] = CommitmentPreimage({
            npk: _npk,
            value: uint120(balance),
            token: _deposits[i]
          });
        }
      } else if (_deposits[i].tokenType == TokenType.ERC721) {
        // ERC721 token
        revert("GeneralAdapt: ERC721 not yet supported");
      } else if (_deposits[i].tokenType == TokenType.ERC1155) {
        // ERC1155 token
        revert("GeneralAdapt: ERC1155 not yet supported");
      } else {
        // Invalid token type, revert
        revert("GeneralAdapt: Unknown token type");
      }
    }

    if (numValidTokens == 0) {
      return;
    }

    // Filter commitmentPreImages for != 0 (remove 0 balance tokens).
    CommitmentPreimage[] memory filteredCommitmentPreimages = new CommitmentPreimage[](numValidTokens);
    uint256[2][] memory filteredEncryptedRandom = new uint256[2][](numValidTokens);

    uint256 filterIndex = 0;
    for (uint256 i = 0; i < numValidTokens; i++) {
      while (commitmentPreimages[filterIndex].value == 0) {
        filterIndex += 1;
      }
      filteredCommitmentPreimages[i] = commitmentPreimages[filterIndex];
      filteredEncryptedRandom[i] = _encryptedRandom;
      filterIndex += 1;
    }

    // Deposit back to Railgun
    railgun.generateDeposit(filteredCommitmentPreimages, filteredEncryptedRandom);
  }

  /**
   * @notice Sends tokens to particular address
   * @param _tokens - tokens to send (0x0 - ERC20 is eth)
   * @param _to - ETH address to send to
   */
   function send(
    TokenData[] calldata _tokens,
    address _to
  ) external onlySelf {
    // Loop through each token specified for deposit and deposit our total balance
    // Due to a quirk with the USDT token contract this will fail if it's approval is
    // non-0 (https://github.com/Uniswap/interface/issues/1034), to ensure that your
    // transaction always succeeds when dealing with USDT/similar tokens make sure the last
    // call in your calls is a call to the token contract with an approval of 0
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_tokens[i].tokenType == TokenType.ERC20) {
        // ERC20 token
        IERC20 token = IERC20(_tokens[i].tokenAddress);

        if (address(token) == address(0x0)) {
          // Fetch ETH balance
          uint256 balance = address(this).balance;

          if (balance > 0) {
            // Send ETH
            // solhint-disable-next-line avoid-low-level-calls
            (bool sent,) = _to.call{value: balance}("");
            require(sent, "Failed to send Ether");
          }
        } else {
          // Fetch balance
          uint256 balance = token.balanceOf(address(this));

          if (balance > 0) {
            // Send all to address
            token.safeTransfer(_to, balance);
          }
        }
      } else if (_tokens[i].tokenType == TokenType.ERC721) {
        // ERC721 token
        revert("RailgunLogic: ERC721 not yet supported");
      } else if (_tokens[i].tokenType == TokenType.ERC1155) {
        // ERC1155 token
        revert("RailgunLogic: ERC1155 not yet supported");
      } else {
        // Invalid token type, revert
        revert("RailgunLogic: Unknown token type");
      }
    }
  }

  /**
   * @notice Wraps all base tokens in contract
   */
  function wrapAllBase() external onlySelf {
    // Fetch ETH balance
    uint256 balance = address(this).balance;

    // Wrap
    wbase.deposit{value: balance}();
  }

  /**
   * @notice Unwraps all wrapped base tokens in contract
   */
  function unwrapAllBase() external onlySelf {
    // Fetch ETH balance
    uint256 balance = wbase.balanceOf(address(this));

    // Unwrap
    wbase.withdraw(balance);
  }

  /**
   * @notice Executes multicall batch
   * @param _requireSuccess - Whether transaction should throw on call failure
   * @param _calls - multicall array
   */
  function multicall(
    bool _requireSuccess,
    Call[] calldata _calls
  ) internal {
    // Initialize returnData array
    Result[] memory returnData = new Result[](_calls.length);

    // Loop through each call
    for(uint256 i = 0; i < _calls.length; i++) {
      // Retrieve call
      Call calldata call = _calls[i];

      // Execute call
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory ret) = call.to.call{value: call.value, gas: gasleft()}(call.data);

      // Add call result to returnData
      returnData[i] = Result(success, string(ret));

      if (success) {
        continue;
      }

      bool isInternalCall = call.to == address(this);
      bool requireSuccess = _requireSuccess || isInternalCall;

      // If requireSuccess is true, throw on failure
      if (requireSuccess) {
        emit CallResult(returnData);
        revert(string.concat("GeneralAdapt Call Failed:", string(ret)));
      }
    }

    emit CallResult(returnData);
  }

  /**
   * @notice Convenience function to get the adapt params value for a given set of transactions
   * and calls
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _random - Random value (shouldn't be reused if resubmitting the same transaction
   * through another relayer or resubmitting on failed transaction - the same nullifier:random
   * should never be reused)
   * @param _minGas - minimum amount of gas to be supplied to transaction
   * @param _requireSuccess - Whether transaction should throw on multicall failure
   * @param _calls - multicall
   */
  function getRelayAdaptParams(
    Transaction[] calldata _transactions,
    uint256 _random,
    bool _requireSuccess,
    uint256 _minGas,
    Call[] calldata _calls
  ) external pure returns (bytes32) {
    // Convenience function to get the expected adaptID parameters value for global
    bytes memory additionalData = abi.encode(
      _random,
      _requireSuccess,
      _minGas,
      _calls
    );

    // Return adapt params value
    return getAdaptParams(_transactions, additionalData);
  }

  /**
   * @notice Executes a batch of Railgun transactions followed by a multicall
   * @param _transactions - Batch of Railgun transactions to execute
   * @param _random - Random value (shouldn't be reused if resubmitting the same transaction
   * through another relayer or resubmitting on failed transaction - the same nullifier:random
   * should never be reused)
   * @param _requireSuccess - Whether transaction should throw on multicall failure
   * @param _minGas - minimum amount of gas to be supplied to transaction
   * @param _calls - multicall
   */
  function relay(
    Transaction[] calldata _transactions,
    uint256 _random,
    bool _requireSuccess,
    uint256 _minGas,
    Call[] calldata _calls
  ) external payable {
    require(gasleft() > _minGas, "Not enough gas supplied");

    if (_transactions.length > 0) {
      // Calculate additionalData parameter for adaptID parameters
      bytes memory additionalData = abi.encode(
        _random,
        _requireSuccess,
        _minGas,
        _calls
      );

      // Executes railgun batch
      railgunBatch(_transactions, additionalData);
    }

    // Execute multicalls
    multicall(_requireSuccess, _calls);

    // To execute a multicall and deposit or send the resulting tokens, encode a call to the relevant function on this
    // contract at the end of your calls array.
  }

  // Allow WBASE contract unwrapping to pay us
  // solhint-disable-next-line avoid-tx-origin no-empty-blocks
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWBase is IERC20 {
  function deposit() external payable;
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { SNARK_SCALAR_FIELD, TokenType, WithdrawType, TokenData, CommitmentCiphertext, CommitmentPreimage, Transaction } from "./Globals.sol";

import { Verifier } from "./Verifier.sol";
import { Commitments } from "./Commitments.sol";
import { TokenBlacklist } from "./TokenBlacklist.sol";
import { PoseidonT4 } from "./Poseidon.sol";

/**
 * @title Railgun Logic
 * @author Railgun Contributors
 * @notice Functions to interact with the railgun contract
 * @dev Wallets for Railgun will only need to interact with functions specified in this contract.
 * This contract is written to be run behind a ERC1967-like proxy. Upon deployment of proxy the _data parameter should
 * call the initializeRailgunLogic function.
 */
contract RailgunLogic is Initializable, OwnableUpgradeable, Commitments, TokenBlacklist, Verifier {
  using SafeERC20 for IERC20;

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Treasury variables
  address payable public treasury; // Treasury contract
  uint120 private constant BASIS_POINTS = 10000; // Number of basis points that equal 100%
  // % fee in 100ths of a %. 100 = 1%.
  uint120 public depositFee;
  uint120 public withdrawFee;

  // Flat fee in wei that applies to NFT transactions
  uint256 public nftFee;

  // Safety vectors
  mapping(uint256 => bool) public snarkSafetyVector;

  // Treasury events
  event TreasuryChange(address treasury);
  event FeeChange(uint256 depositFee, uint256 withdrawFee, uint256 nftFee);

  // Transaction events
  event CommitmentBatch(
    uint256 treeNumber,
    uint256 startPosition,
    uint256[] hash,
    CommitmentCiphertext[] ciphertext
  );

  event GeneratedCommitmentBatch(
    uint256 treeNumber,
    uint256 startPosition,
    CommitmentPreimage[] commitments,
    uint256[2][] encryptedRandom
  );

  event Nullifiers(uint256 treeNumber, uint256[] nullifier);

  /**
   * @notice Initialize Railgun contract
   * @dev OpenZeppelin initializer ensures this can only be called once
   * This function also calls initializers on inherited contracts
   * @param _treasury - address to send usage fees to
   * @param _depositFee - Deposit fee
   * @param _withdrawFee - Withdraw fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   * @param _owner - governance contract
   */
  function initializeRailgunLogic(
    address payable _treasury,
    uint120 _depositFee,
    uint120 _withdrawFee,
    uint256 _nftFee,
    address _owner
  ) external initializer {
    // Call initializers
    OwnableUpgradeable.__Ownable_init();
    Commitments.initializeCommitments();

    // Set treasury and fee
    changeTreasury(_treasury);
    changeFee(_depositFee, _withdrawFee, _nftFee);

    // Change Owner
    OwnableUpgradeable.transferOwnership(_owner);

    // Set safety vectors
    snarkSafetyVector[11991246288605609459798790887503763024866871101] = true;
    snarkSafetyVector[135932600361240492381964832893378343190771392134] = true;
    snarkSafetyVector[1165567609304106638376634163822860648671860889162] = true;
  }

  /**
   * @notice Change treasury address, only callable by owner (governance contract)
   * @dev This will change the address of the contract we're sending the fees to in the future
   * it won't transfer tokens already in the treasury
   * @param _treasury - Address of new treasury contract
   */
  function changeTreasury(address payable _treasury) public onlyOwner {
    // Do nothing if the new treasury address is same as the old
    if (treasury != _treasury) {
      // Change treasury
      treasury = _treasury;

      // Emit treasury change event
      emit TreasuryChange(_treasury);
    }
  }

  /**
   * @notice Change fee rate for future transactions
   * @param _depositFee - Deposit fee
   * @param _withdrawFee - Withdraw fee
   * @param _nftFee - Flat fee in wei that applies to NFT transactions
   */
  function changeFee(
    uint120 _depositFee,
    uint120 _withdrawFee,
    uint256 _nftFee
  ) public onlyOwner {
    if (
      _depositFee != depositFee
      || _withdrawFee != withdrawFee
      || nftFee != _nftFee
    ) {
      require(_depositFee <= BASIS_POINTS, "RailgunLogic: Deposit Fee exceeds 100%");
      require(_withdrawFee <= BASIS_POINTS, "RailgunLogic: Withdraw Fee exceeds 100%");

      // Change fee
      depositFee = _depositFee;
      withdrawFee = _withdrawFee;
      nftFee = _nftFee;

      // Emit fee change event
      emit FeeChange(_depositFee, _withdrawFee, _nftFee);
    }
  }

  /**
   * @notice Get base and fee amount
   * @param _amount - Amount to calculate for
   * @param _isInclusive - Whether the amount passed in is inclusive of the fee
   * @param _feeBP - Fee basis points
   * @return base, fee
   */
  function getFee(uint136 _amount, bool _isInclusive, uint120 _feeBP) public pure returns (uint120, uint120) {
    // Expand width of amount to uint136 to accomodate full size of (2**120-1)*BASIS_POINTS
    uint136 amountExpanded = _amount;

    // Base is the amount deposited into the railgun contract or withdrawn to the target eth address
    // for deposits and withdraws respectively
    uint136 base;
    // Fee is the amount sent to the treasury
    uint136 fee;

    if (_isInclusive) {
      base = amountExpanded - (amountExpanded * _feeBP) / BASIS_POINTS;
      fee = amountExpanded - base;
    } else {
      base = amountExpanded;
      fee = (BASIS_POINTS * base) / (BASIS_POINTS - _feeBP) - base;
    }

    return (uint120(base), uint120(fee));
  }

  /**
   * @notice Gets token field value from tokenData
   * @param _tokenData - tokenData to calculate token field from
   * @return token field
   */
  function getTokenField(TokenData memory _tokenData) public pure returns (uint256) {
    if (_tokenData.tokenType == TokenType.ERC20) {
      return uint256(uint160(_tokenData.tokenAddress));
    } else if (_tokenData.tokenType == TokenType.ERC721) {
      revert("RailgunLogic: ERC721 not yet supported");
    } else if (_tokenData.tokenType == TokenType.ERC1155) {
      revert("RailgunLogic: ERC1155 not yet supported");
    } else {
      revert("RailgunLogic: Unknown token type");
    }
  }

  /**
   * @notice Hashes a commitment
   * @param _commitmentPreimage - commitment to hash
   * @return commitment hash
   */
  function hashCommitment(CommitmentPreimage memory _commitmentPreimage) public pure returns (uint256) {
    return PoseidonT4.poseidon([
      _commitmentPreimage.npk,
      getTokenField(_commitmentPreimage.token),
      _commitmentPreimage.value
    ]);
  }

  /**
   * @notice Deposits requested amount and token, creates a commitment hash from supplied values and adds to tree
   * @param _notes - list of commitments to deposit
   */
  function generateDeposit(CommitmentPreimage[] calldata _notes, uint256[2][] calldata _encryptedRandom) external {
    // Get notes length
    uint256 notesLength = _notes.length;

    // Insertion and event arrays
    uint256[] memory insertionLeaves = new uint256[](notesLength);
    CommitmentPreimage[] memory generatedCommitments = new CommitmentPreimage[](notesLength);

    require(_notes.length == _encryptedRandom.length, "RailgunLogic: notes and encrypted random length doesn't match");

    for (uint256 notesIter = 0; notesIter < notesLength; notesIter++) {
      // Retrieve note
      CommitmentPreimage calldata note = _notes[notesIter];

      // Check deposit amount is not 0
      require(note.value > 0, "RailgunLogic: Cannot deposit 0 tokens");

      // Check if token is on the blacklist
      require(
        !TokenBlacklist.tokenBlacklist[note.token.tokenAddress],
        "RailgunLogic: Token is blacklisted"
      );

      // Check ypubkey is in snark scalar field
      require(note.npk < SNARK_SCALAR_FIELD, "RailgunLogic: npk out of range");

      // Process deposit request
      if (note.token.tokenType == TokenType.ERC20) {
        // ERC20

        // Get ERC20 interface
        IERC20 token = IERC20(address(uint160(note.token.tokenAddress)));

        // Get base and fee amounts
        (uint120 base, uint120 fee) = getFee(note.value, true, depositFee);

        // Add GeneratedCommitment to event array
        generatedCommitments[notesIter] = CommitmentPreimage({
          npk: note.npk,
          value: base,
          token: note.token
        });

        // Calculate commitment hash
        uint256 hash = hashCommitment(generatedCommitments[notesIter]);

        // Add to insertion array
        insertionLeaves[notesIter] = hash;

        // Transfer base to output address
        token.safeTransferFrom(
          address(msg.sender),
          address(this),
          base
        );

        // Transfer fee to treasury
        token.safeTransferFrom(
          address(msg.sender),
          treasury,
          fee
        );
      } else if (note.token.tokenType == TokenType.ERC721) {
        // ERC721 token
        revert("RailgunLogic: ERC721 not yet supported");
      } else if (note.token.tokenType == TokenType.ERC1155) {
        // ERC1155 token
        revert("RailgunLogic: ERC1155 not yet supported");
      } else {
        // Invalid token type, revert
        revert("RailgunLogic: Unknown token type");
      }
    }

    // Emit GeneratedCommitmentAdded events (for wallets) for the commitments
    emit GeneratedCommitmentBatch(Commitments.treeNumber, Commitments.nextLeafIndex, generatedCommitments, _encryptedRandom);

    // Push new commitments to merkle tree
    Commitments.insertLeaves(insertionLeaves);
  }

  /**
   * @notice Safety check for badly behaving code
   */
  function checkSafetyVectors() external {
    // Set safety bit
    StorageSlot.getBooleanSlot(0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450).value = true;

    // Setup behaviour check
    bool result = false;

    // Execute behaviour check
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0, caller())
      mstore(32, snarkSafetyVector.slot)
      let hash := keccak256(0, 64)
      result := sload(hash)
    }

    require(result, "RailgunLogic: Unsafe vectors");
  }

  /**
   * @notice Adds safety vector
   */
  function addVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = true;
  }

  /**
   * @notice Removes safety vector
   */
  function removeVector(uint256 vector) external onlyOwner {
    snarkSafetyVector[vector] = false;
  }

  /**
   * @notice Execute batch of Railgun snark transactions
   * @param _transactions - Transactions to execute
   */
  function transact(
    Transaction[] calldata _transactions
  ) external {
    // Accumulate total number of insertion commitments
    uint256 insertionCommitmentCount = 0;

    // Loop through each transaction
    uint256 transactionLength = _transactions.length;
    for(uint256 transactionIter = 0; transactionIter < transactionLength; transactionIter++) {
      // Retrieve transaction
      Transaction calldata transaction = _transactions[transactionIter];

      // If adaptContract is not zero check that it matches the caller
      require(
        transaction.boundParams.adaptContract == address (0) || transaction.boundParams.adaptContract == msg.sender,
        "AdaptID doesn't match caller contract"
      );

      // Retrieve treeNumber
      uint256 treeNumber = transaction.boundParams.treeNumber;

      // Check merkle root is valid
      require(Commitments.rootHistory[treeNumber][transaction.merkleRoot], "RailgunLogic: Invalid Merkle Root");

      // Loop through each nullifier
      uint256 nullifiersLength = transaction.nullifiers.length;
      for (uint256 nullifierIter = 0; nullifierIter < nullifiersLength; nullifierIter++) {
        // Retrieve nullifier
        uint256 nullifier = transaction.nullifiers[nullifierIter];

        // Check if nullifier has been seen before
        require(!Commitments.nullifiers[treeNumber][nullifier], "RailgunLogic: Nullifier already seen");

        // Push to nullifiers
        Commitments.nullifiers[treeNumber][nullifier] = true;
      }

      // Emit nullifiers event
      emit Nullifiers(treeNumber, transaction.nullifiers);

      // Verify proof
      require(
        Verifier.verify(transaction),
        "RailgunLogic: Invalid SNARK proof"
      );

      if (transaction.boundParams.withdraw != WithdrawType.NONE) {
        // Last output is marked as withdraw, process
        // Hash the withdraw commitment preimage
        uint256 commitmentHash = hashCommitment(transaction.withdrawPreimage);

        // Make sure the commitment hash matches the withdraw transaction output
        require(
          commitmentHash == transaction.commitments[transaction.commitments.length - 1],
          "RailgunLogic: Withdraw commitment preimage is invalid"
        );

        // Fetch output address
        address output = address(uint160(transaction.withdrawPreimage.npk));

        // Check if we've been asked to override the withdraw destination
        if(transaction.overrideOutput != address(0)) {
          // Withdraw must == 2 and msg.sender must be the original recepient to change the output destination
          require(
            msg.sender == output && transaction.boundParams.withdraw == WithdrawType.REDIRECT,
            "RailgunLogic: Can't override destination address"
          );

          // Override output address
          output = transaction.overrideOutput;
        }

        // Process withdrawal request
        if (transaction.withdrawPreimage.token.tokenType == TokenType.ERC20) {
          // ERC20

          // Get ERC20 interface
          IERC20 token = IERC20(address(uint160(transaction.withdrawPreimage.token.tokenAddress)));

          // Get base and fee amounts
          (uint120 base, uint120 fee) = getFee(transaction.withdrawPreimage.value, true, withdrawFee);

          // Transfer base to output address
          token.safeTransfer(
            output,
            base
          );

          // Transfer fee to treasury
          token.safeTransfer(
            treasury,
            fee
          );
        } else if (transaction.withdrawPreimage.token.tokenType == TokenType.ERC721) {
          // ERC721 token
          revert("RailgunLogic: ERC721 not yet supported");
        } else if (transaction.withdrawPreimage.token.tokenType == TokenType.ERC1155) {
          // ERC1155 token
          revert("RailgunLogic: ERC1155 not yet supported");
        } else {
          // Invalid token type, revert
          revert("RailgunLogic: Unknown token type");
        }

        // Ensure ciphertext length matches the commitments length (minus 1 for withdrawn output)
        require(
          transaction.boundParams.commitmentCiphertext.length == transaction.commitments.length - 1,
          "RailgunLogic: Ciphertexts and commitments count mismatch"
        );

        // Increment insertion commitment count (minus 1 for withdrawn output)
        insertionCommitmentCount += transaction.commitments.length - 1;
      } else {
        // Ensure ciphertext length matches the commitments length
        require(
          transaction.boundParams.commitmentCiphertext.length == transaction.commitments.length,
          "RailgunLogic: Ciphertexts and commitments count mismatch"
        );

        // Increment insertion commitment count
        insertionCommitmentCount += transaction.commitments.length;
      }
    }

    // Create insertion array
    uint256[] memory hashes = new uint256[](insertionCommitmentCount);

    // Create ciphertext array
    CommitmentCiphertext[] memory ciphertext = new CommitmentCiphertext[](insertionCommitmentCount);

    // Track insert position
    uint256 insertPosition = 0;

    // Loop through each transaction and accumulate commitments
    for(uint256 transactionIter = 0; transactionIter < _transactions.length; transactionIter++) {
      // Retrieve transaction
      Transaction calldata transaction = _transactions[transactionIter];

      // Loop through commitments and push to array
      uint256 commitmentLength = transaction.boundParams.commitmentCiphertext.length;
      for(uint256 commitmentIter = 0; commitmentIter < commitmentLength; commitmentIter++) {
        // Push commitment hash to array
        hashes[insertPosition] = transaction.commitments[commitmentIter];

        // Push ciphertext to array
        ciphertext[insertPosition] = transaction.boundParams.commitmentCiphertext[commitmentIter];

        // Increment insert position
        insertPosition++;
      }
    }

    // Emit commitment state update
    emit CommitmentBatch(Commitments.treeNumber, Commitments.nextLeafIndex, hashes, ciphertext);

    // Push new commitments to merkle tree after event due to insertLeaves causing side effects
    Commitments.insertLeaves(hashes);
  }
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint256 constant CIPHERTEXT_WORDS = 4;

enum TokenType { ERC20, ERC721, ERC1155 }

// Transaction token data
struct TokenData {
  TokenType tokenType;
  address tokenAddress;
  uint256 tokenSubID;
}

// Commitment ciphertext
struct CommitmentCiphertext {
  uint256[CIPHERTEXT_WORDS] ciphertext; // Ciphertext order: iv & tag (16 bytes each), recipient master public key (packedPoint) (uint256), packedField (uint256) {sign, random, amount}, token (uint256)
  uint256[2] ephemeralKeys; // Sender first, receipient second (packed points 32 bytes each)
  uint256[] memo;
}

enum WithdrawType { NONE, WITHDRAW, REDIRECT }

// Transaction bound parameters
struct BoundParams {
  uint16 treeNumber;
  WithdrawType withdraw;
  address adaptContract;
  bytes32 adaptParams;
  // For withdraws do not include an element in ciphertext array
  // Ciphertext array length = commitments - withdraws
  CommitmentCiphertext[] commitmentCiphertext;
}

// Transaction struct
struct Transaction {
  SnarkProof proof;
  uint256 merkleRoot;
  uint256[] nullifiers;
  uint256[] commitments;
  BoundParams boundParams;
  CommitmentPreimage withdrawPreimage;
  address overrideOutput; // Only allowed if original destination == msg.sender & boundParams.withdraw == 2
}

// Commitment hash preimage
struct CommitmentPreimage {
  uint256 npk; // Poseidon(mpk, random), mpk = Poseidon(spending public key, nullifier)
  TokenData token; // Token field
  uint120 value; // Note value
}

struct G1Point {
  uint256 x;
  uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
  uint256[2] x;
  uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
  string artifactsIPFSHash;
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[] ic;
}

// Snark proof for transaction
struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { SnarkProof, Transaction, BoundParams, VerifyingKey, SNARK_SCALAR_FIELD } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/**
 * @title Verifier
 * @author Railgun Contributors
 * @notice Verifies snark proof
 * @dev Functions in this contract statelessly verify proofs, nullifiers and adaptID should be checked in RailgunLogic.
 */
contract Verifier is OwnableUpgradeable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement __gap
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Snark bypass address, can't be address(0) as many burn prevention mechanisms will disallow transfers to 0
  // Use 0x000000000000000000000000000000000000dEaD as an alternative
  address constant public SNARK_BYPASS = 0x000000000000000000000000000000000000dEaD;

  // Verifying key set event
  event VerifyingKeySet(uint256 nullifiers, uint256 commitments, VerifyingKey verifyingKey);

  // Nullifiers => Commitments => Verification Key
  mapping(uint256 => mapping(uint256 => VerifyingKey)) private verificationKeys;

  /**
   * @notice Sets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitmets out this verification key is for
   * @param _verifyingKey - verifyingKey to set
   */
  function setVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments,
    VerifyingKey calldata _verifyingKey
  ) public onlyOwner {
    verificationKeys[_nullifiers][_commitments] = _verifyingKey;

    emit VerifyingKeySet(_nullifiers, _commitments, _verifyingKey);
  }

  /**
   * @notice Gets verification key
   * @param _nullifiers - number of nullifiers this verification key is for
   * @param _commitments - number of commitmets out this verification key is for
   */
  function getVerificationKey(
    uint256 _nullifiers,
    uint256 _commitments
  ) public view returns (VerifyingKey memory) {
    // Manually add getter so dynamic IC array is included in response
    return verificationKeys[_nullifiers][_commitments];
  }

  /**
   * @notice Calculates hash of transaction bound params for snark verification
   * @param _boundParams - bound parameters
   * @return bound parameters hash
   */
  function hashBoundParams(BoundParams calldata _boundParams) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(
      _boundParams
    ))) % SNARK_SCALAR_FIELD;
  }

  /**
   * @notice Verifies inputs against a verification key
   * @param _verifyingKey - verifying key to verify with
   * @param _proof - proof to verify
   * @param _inputs - input to verify
   * @return proof validity
   */
  function verifyProof(
    VerifyingKey memory _verifyingKey,
    SnarkProof calldata _proof,
    uint256[] memory _inputs
  ) public view returns (bool) {
    return Snark.verify(
      _verifyingKey,
      _proof,
      _inputs
    );
  }

  /**
   * @notice Verifies a transaction
   * @param _transaction to verify
   * @return transaction validity
   */
  function verify(Transaction calldata _transaction) public view returns (bool) {
    uint256 nullifiersLength = _transaction.nullifiers.length;
    uint256 commitmentsLength = _transaction.commitments.length;

    // Retrieve verification key
    VerifyingKey memory verifyingKey = verificationKeys
      [nullifiersLength]
      [commitmentsLength];

    // Check if verifying key is set
    require(verifyingKey.alpha1.x != 0, "Verifier: Key not set");

    // Calculate inputs
    uint256[] memory inputs = new uint256[](2 + nullifiersLength + commitmentsLength);
    inputs[0] = _transaction.merkleRoot;
    
    // Hash bound parameters
    inputs[1] = hashBoundParams(_transaction.boundParams);

    // Loop through nullifiers and add to inputs
    for (uint i = 0; i < nullifiersLength; i++) {
      inputs[2 + i] = _transaction.nullifiers[i];
    }

    // Loop through commitments and add to inputs
    for (uint i = 0; i < commitmentsLength; i++) {
      inputs[2 + nullifiersLength + i] = _transaction.commitments[i];
    }
    
    // Verify snark proof
    bool validity = verifyProof(
      verifyingKey,
      _transaction.proof,
      inputs
    );

    // Always return true in gas estimation transaction
    // This is so relayer fees can be calculated without needing to compute a proof
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin == SNARK_BYPASS) {
      return true;
    } else {
      return validity;
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// Based on code from MACI (https://github.com/appliedzkp/maci/blob/7f36a915244a6e8f98bacfe255f8bd44193e7919/contracts/sol/IncrementalMerkleTree.sol)
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { SNARK_SCALAR_FIELD } from "./Globals.sol";

import { PoseidonT3 } from "./Poseidon.sol";

/**
 * @title Commitments
 * @author Railgun Contributors
 * @notice Batch Incremental Merkle Tree for commitments
 * @dev Publically accessible functions to be put in RailgunLogic
 * Relevent external contract calls should be in those functions, not here
 */
contract Commitments is Initializable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Commitment nullifiers (treenumber -> nullifier -> seen)
  mapping(uint256 => mapping(uint256 => bool)) public nullifiers;

  // The tree depth
  uint256 internal constant TREE_DEPTH = 16;

  // Tree zero value
  uint256 public constant ZERO_VALUE = uint256(keccak256("Railgun")) % SNARK_SCALAR_FIELD;

  // Next leaf index (number of inserted leaves in the current tree)
  uint256 internal nextLeafIndex;

  // The Merkle root
  uint256 public merkleRoot;

  // Store new tree root to quickly migrate to a new tree
  uint256 private newTreeRoot;

  // Tree number
  uint256 public treeNumber;

  // The Merkle path to the leftmost leaf upon initialisation. It *should
  // not* be modified after it has been set by the initialize function.
  // Caching these values is essential to efficient appends.
  uint256[TREE_DEPTH] public zeros;

  // Right-most elements at each level
  // Used for efficient upodates of the merkle tree
  uint256[TREE_DEPTH] private filledSubTrees;

  // Whether the contract has already seen a particular Merkle tree root
  // treeNumber -> root -> seen
  mapping(uint256 => mapping(uint256 => bool)) public rootHistory;


  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev OpenZeppelin initializer ensures this can only be called once
   */
  function initializeCommitments() internal onlyInitializing {
    /*
    To initialise the Merkle tree, we need to calculate the Merkle root
    assuming that each leaf is the zero value.
    H(H(a,b), H(c,d))
      /          \
    H(a,b)     H(c,d)
    /   \       /  \
    a    b     c    d
    `zeros` and `filledSubTrees` will come in handy later when we do
    inserts or updates. e.g when we insert a value in index 1, we will
    need to look up values from those arrays to recalculate the Merkle
    root.
    */

    // Calculate zero values
    zeros[0] = ZERO_VALUE;

    // Store the current zero value for the level we just calculated it for
    uint256 currentZero = ZERO_VALUE;

    // Loop through each level
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      // Push it to zeros array
      zeros[i] = currentZero;

      // Calculate the zero value for this level
      currentZero = hashLeftRight(currentZero, currentZero);
    }

    // Set merkle root and store root to quickly retrieve later
    newTreeRoot = merkleRoot = currentZero;
    rootHistory[treeNumber][currentZero] = true;
  }

  /**
   * @notice Hash 2 uint256 values
   * @param _left - Left side of hash
   * @param _right - Right side of hash
   * @return hash result
   */
  function hashLeftRight(uint256 _left, uint256 _right) public pure returns (uint256) {
    return PoseidonT3.poseidon([
      _left,
      _right
    ]);
  }

  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev Insert leaves into the current merkle tree
   * Note: this function INTENTIONALLY causes side effects to save on gas.
   * _leafHashes and _count should never be reused.
   * @param _leafHashes - array of leaf hashes to be added to the merkle tree
   */
  function insertLeaves(uint256[] memory _leafHashes) internal {
    /*
    Loop through leafHashes at each level, if the leaf is on the left (index is even)
    then hash with zeros value and update subtree on this level, if the leaf is on the
    right (index is odd) then hash with subtree value. After calculating each hash
    push to relevent spot on leafHashes array. For gas efficiency we reuse the same
    array and use the count variable to loop to the right index each time.

    Example of updating a tree of depth 4 with elements 13, 14, and 15
    [1,7,15]    {1}                    1
                                       |
    [3,7,15]    {1}          2-------------------3
                             |                   |
    [6,7,15]    {2}     4---------5         6---------7
                       / \       / \       / \       / \
    [13,14,15]  {3}  08   09   10   11   12   13   14   15
    [] = leafHashes array
    {} = count variable
    */

    // Get initial count
    uint256 count = _leafHashes.length;

    // Create new tree if current one can't contain new leaves
    // We insert all new commitment into a new tree to ensure they can be spent in the same transaction
    if ((nextLeafIndex + count) >= (2 ** TREE_DEPTH)) { newTree(); }

    // Current index is the index at each level to insert the hash
    uint256 levelInsertionIndex = nextLeafIndex;

    // Update nextLeafIndex
    nextLeafIndex += count;

    // Variables for starting point at next tree level
    uint256 nextLevelHashIndex;
    uint256 nextLevelStartIndex;

    // Loop through each level of the merkle tree and update
    for (uint256 level = 0; level < TREE_DEPTH; level++) {
      // Calculate the index to start at for the next level
      // >> is equivilent to / 2 rounded down
      nextLevelStartIndex = levelInsertionIndex >> 1;

      uint256 insertionElement = 0;

      // If we're on the right, hash and increment to get on the left
      if (levelInsertionIndex % 2 == 1) {
        // Calculate index to insert hash into leafHashes[]
        // >> is equivilent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(filledSubTrees[level], _leafHashes[insertionElement]);

        // Increment
        insertionElement += 1;
        levelInsertionIndex += 1;
      }

      // We'll always be on the left side now
      for (insertionElement; insertionElement < count; insertionElement += 2) {
        uint256 right;

        // Calculate right value
        if (insertionElement < count - 1) {
          right = _leafHashes[insertionElement + 1];
        } else {
          right = zeros[level];
        }

        // If we've created a new subtree at this level, update
        if (insertionElement == count - 1 || insertionElement == count - 2) {
          filledSubTrees[level] = _leafHashes[insertionElement];
        }

        // Calculate index to insert hash into leafHashes[]
        // >> is equivilent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(_leafHashes[insertionElement], right);

        // Increment level insertion index
        levelInsertionIndex += 2;
      }

      // Get starting levelInsertionIndex value for next level
      levelInsertionIndex = nextLevelStartIndex;

      // Get count of elements for next level
      count = nextLevelHashIndex + 1;
    }
 
    // Update the Merkle tree root
    merkleRoot = _leafHashes[0];
    rootHistory[treeNumber][merkleRoot] = true;
  }

  /**
   * @notice Creates new merkle tree
   */
  function newTree() internal {
    // Restore merkleRoot to newTreeRoot
    merkleRoot = newTreeRoot;

    // Existing values in filledSubtrees will never be used so overwriting them is unnecessary

    // Reset next leaf index to 0
    nextLeafIndex = 0;

    // Increment tree number
    treeNumber++;
  }

  uint256[10] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Token Blacklist
 * @author Railgun Contributors
 * @notice Blacklist of tokens that are incompatible with the protocol
 * @dev Tokens on this blacklist can't be deposited to railgun.
 * Tokens on this blacklist will still be transferrable
 * internally (as internal transactions have a shielded token ID) and
 * withdrawable (to prevent user funds from being locked)
 * THIS WILL ALWAYS BE A NON-EXHAUSTIVE LIST, DO NOT RELY ON IT BLOCKING ALL
 * INCOMPATIBLE TOKENS
 */
contract TokenBlacklist is OwnableUpgradeable {
  // Events for offchain building of blacklist index
  event AddToBlacklist(address indexed token);
  event RemoveFromBlacklist(address indexed token);

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading
  mapping(address => bool) public tokenBlacklist;

  /**
   * @notice Adds tokens to blacklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that are already in the blacklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to add to blacklist
   */
  function addToBlacklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i++) {
      // Don't do anything if the token is already blacklisted
      if (!tokenBlacklist[_tokens[i]]) {
          // Set token address in blacklist map to true
        tokenBlacklist[_tokens[i]] = true;

        // Emit event for building index of blacklisted tokens offchain
        emit AddToBlacklist(_tokens[i]);
      }
    }
  }

  /**
   * @notice Removes token from blacklist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that aren't in the blacklist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to remove from blacklist
   */
  function removeFromBlacklist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint256 i = 0; i < _tokens.length; i++) {
      // Don't do anything if the token isn't blacklisted
      if (tokenBlacklist[_tokens[i]]) {
        // Set token address in blacklisted map to false (default value)
        delete tokenBlacklist[_tokens[i]];

        // Emit event for building index of blacklisted tokens offchain
        emit RemoveFromBlacklist(_tokens[i]);
      }
    }
  }

  uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

/*
Functions here are stubs for the solidity compiler to generate the right interface.
The deployed library is generated bytecode from the circomlib toolchain
*/

library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

library PoseidonT4 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[3] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
  uint256 private constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 private constant PAIRING_INPUT_SIZE = 24;
  uint256 private constant PAIRING_INPUT_WIDTH = 768; // PAIRING_INPUT_SIZE * 32

  /**
   * @notice Computes the negation of point p
   * @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
   * @return result
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    if (p.x == 0 && p.y == 0) return G1Point(0, 0);

    // check for valid points y^2 = x^3 +3 % PRIME_Q
    uint256 rh = mulmod(p.x, p.x, PRIME_Q); //x^2
    rh = mulmod(rh, p.x, PRIME_Q); //x^3
    rh = addmod(rh, 3, PRIME_Q); //x^3 + 3
    uint256 lh = mulmod(p.y, p.y, PRIME_Q); //y^2
    require(lh == rh, "Snark: Invalid negation");

    return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }

  /**
   * @notice Adds 2 G1 points
   * @return result
   */
  function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    // Format inputs
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;

    // Setup output variables
    bool success;
    G1Point memory result;

    // Add points
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
    }

    // Check if operation succeeded
    require(success, "Snark: Add Failed");

    return result;
  }

  /**
   * @notice Scalar multiplies two G1 points p, s
   * @dev The product of a point on G1 and a scalar, i.e.
   * p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   * points p.
   * @return r - result
   */
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
    }

    // Check multiplication succeeded
    require(success, "Snark: Scalar Multiplication Failed");
  }

  /**
   * @notice Performs pairing check on points
   * @dev The result of computing the pairing check
   * e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   * For example,
   * pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   * @return if pairing check passed
   */
  function pairing(
    G1Point memory _a1,
    G2Point memory _a2,
    G1Point memory _b1,
    G2Point memory _b2,
    G1Point memory _c1,
    G2Point memory _c2,
    G1Point memory _d1,
    G2Point memory _d2
  ) internal view returns (bool) {
    uint256[PAIRING_INPUT_SIZE] memory input = [
      _a1.x,
      _a1.y,
      _a2.x[0],
      _a2.x[1],
      _a2.y[0],
      _a2.y[1],
      _b1.x,
      _b1.y,
      _b2.x[0],
      _b2.x[1],
      _b2.y[0],
      _b2.y[1],
      _c1.x,
      _c1.y,
      _c2.x[0],
      _c2.x[1],
      _c2.y[0],
      _c2.y[1],
      _d1.x,
      _d1.y,
      _d2.x[0],
      _d2.x[1],
      _d2.y[0],
      _d2.y[1]
    ];

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        input,
        PAIRING_INPUT_WIDTH,
        out,
        0x20
      )
    }

    // Check if operation succeeded
    require(success, "Snark: Pairing Verification Failed");

    return out[0] != 0;
  }

  /**
    * @notice Verifies snark proof against proving key
    * @param _vk - Verification Key
    * @param _proof - snark proof
    * @param _inputs - inputs
    */
  function verify(
    VerifyingKey memory _vk,
    SnarkProof memory _proof,
    uint256[] memory _inputs
  ) internal view returns (bool) {
    // Compute the linear combination vkX
    G1Point memory vkX = G1Point(0, 0);
    
    // Loop through every input
    for (uint i = 0; i < _inputs.length; i++) {
      // Make sure inputs are less than SNARK_SCALAR_FIELD
      require(_inputs[i] < SNARK_SCALAR_FIELD, "Snark: Input > SNARK_SCALAR_FIELD");

      // Add to vkX point
      vkX = add(vkX, scalarMul(_vk.ic[i + 1], _inputs[i]));
  }

    // Compute final vkX point
    vkX = add(vkX, _vk.ic[0]);

    // Verify pairing and return
    return pairing(
      negate(_proof.a),
      _proof.b,
      _vk.alpha1,
      _vk.beta2,
      vkX,
      _vk.gamma2,
      _proof.c,
      _vk.delta2
    );
  }
}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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

/**
                                                                                               
                                       THE DECENTRALISTS                                       
                                                                                               
                                ·.::::iiiiiiiiiiiiiiiiiii::::.·                                
                           .:::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii::.·                          
                       .::iiiiiiiii:::::..···      ··..:::::iiiiiiiiii::·                      
                   .::iiiiiii:::.·                            .:::iiiiiii::.                   
                .:iiiiiii::                                         .:iiiiiii:.                
             ·:iiiiii::·                                                ::iiiiii:·             
            :iiiiii:·                 ·.::::::::::::::..                   :iiiiii:·           
          :iiiii::               .:::iiiii:::::::::::iiiii:::.               .:iiiii:·         
        :iiiii:·            ·::iii:::·                   .:::iii::·             :iiiii:·       
      ·iiiii:·            ::iii:·                             .::ii::            ·:iiiii:      
     :iiiii:           ·:ii::·                                   ·:iii:·           .iiiii:     
    :iiiii·          ·:ii:.                                         ·:ii:           ·:iiii:    
   :iiii:          ·:ii:              ·.:::::::i:::::::.·             ·:ii:           :iiiii   
  :iiii:          ·iii:            .::iiiiiiiiiiiiiiiiii:::·            .ii:           .iiii:  
 ·iiiii          ·iii            .:ii:::::::iiiiiiiiiiiiiii::.           ·:i:·          :iiii: 
 :iiii:         ·:i:·          .:iii:      .:iiiiiiiiiiiiiiiii:.           iii           iiiii 
:iiii:          :ii           :iiiii:·     ::iiiiiiiiiiiiiiiiiii:          ·ii:          :iiii:
iiiii·         ·ii:          ::iiiiii::::::iiiiiiiiiiiiiiiiiiiiii.          :ii.         ·iiiii
iiiii          :ii           :iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:·         .ii:          :iiii
iiiii          :ii          .iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii.          ii:          :iiii
iiiii          :ii          .iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:.          ii:          :iiii
iiiii          :ii           :iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:·         .ii:          :iiii
iiiii·         ·ii:          ::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:.          :ii.         ·iiiii
:iiii:          :ii           .:iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:          ·ii:          :iiii:
 :iiii:         ·:i:·          ·::iiiiiiiiiiiiiiiiiiiiiiiiiiii:·           ii:           iiiii 
 ·iiiii           iii·           ·::iiiiiiiiiiiiiiiiiiiiiii::.           .ii:·          :iiii: 
  :iiii:           iii:            ·:::iiiiiiiiiiiiiiiii:::·            :ii:           .iiii:  
   :iiii:           :ii:·              .::::::::::::::..              .:ii:           :iiii:   
    :iiiii·           :iii:                                         .:ii:           ·:iiii:    
     :iiiii:            :iii:·                                   .:iii:·           .iiiii:     
      ·iiiii:·            .:iii:.·                            ::iii::            ·:iiiii:      
        :iiiii:·             .:iiii::.·                 ·:::iiii:.              :iiiii:·       
          :iiiii::               ·:::iiiiiii:::::::iiiiiii:::·               .:iiiii:·         
            :iiiiii:·                   ..:::::::::::..·                   :iiiiii:·           
             ·:iiiiii::·                                                ::iiiiii:·             
                .:iiiiiii::                                         .:iiiiiii:.                
                   .::iiiiiii:::.·                            .:::iiiiiii::.                   
                       .::iiiiiiiii:::::..···      ··..:::::iiiiiiiiii::·                      
                           .:::iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii::.·                          
                                ·.::::iiiiiiiiiiiiiiiiiii::::.·                                


A Decentralist is represented by a set of eight traits:
  0 - Base
    [0] Human Male Black       [8] Vampire Male       [10] Metahuman Male       [12] Ape Male
    [1] Human Female Black     [9] Vampire Female     [11] Metahuman Female
    [2] Human Male Dark
    [3] Human Female Dark
    [4] Human Male Pale
    [5] Human Female Pale
    [6] Human Male White
    [7] Human Female White
  1 - Necklace
    [0] None        [2] Golden
    [1] Diamond     [3] Silver
  2 - Facial Male
    [0] None             [10] Long Gray           [20] Sideburns Blonde
    [1] Chivo Black      [11] Long Red            [21] Sideburns Brown
    [2] Chivo Blonde     [12] Long White          [22] Sideburns Gray
    [3] Chivo Brown      [13] Regular Black       [23] Sideburns Red
    [4] Chivo Gray       [14] Regular Blonde      [24] Sideburns White
    [5] Chivo Red        [15] Regular Brown
    [6] Chivo White      [16] Regular Gray
    [7] Long Black       [17] Regular Red
    [8] Long Blonde      [18] Regular White
    [9] Long Brown       [19] Sideburns Black
  2 - Facial Female
    [0]  None
  3 - Earring
    [0]  None      [2]  Diamond     [4]  Silver
    [1]  Cross     [3]  Golden
  4 - Head Male
    [0] None                [10] CapFront Red     [20] Punky Brown      [30] Short White
    [1] Afro                [11] Hat Black        [21] Punky Gray       [31] Trapper
    [2] CapUp Green         [12] Long Black       [22] Punky Purple     [32] Wool Blue
    [3] CapUp Red           [13] Long Blonde      [23] Punky Red        [33] Wool Green
    [4] Kangaroo Black      [14] Long Brown       [24] Punky White      [34] Wool Red
    [5] CapBack Blue        [15] Long Gray        [25] Short Black
    [6] CapBack Orange      [16] Long Red         [26] Short Blonde
    [7] Conspiracist        [17] Long White       [27] Short Brown
    [8] Cop                 [18] Punky Black      [28] Short Gray
    [9] CapFront Purple     [19] Punky Blonde     [29] Short Red
  4 - Head Female
    [0] None                [10] CapFront Red     [20] Punky Brown      [30] Short White           [40] Trapper
    [1] Afro                [11] Hat Black        [21] Punky Gray       [31] Straight Black        [41] Wool Blue
    [2] CapUp Green         [12] Long Black       [22] Punky Purple     [32] Straight Blonde       [42] Wool Green
    [3] CapUp Red           [13] Long Blonde      [23] Punky Red        [33] Straight Brown        [43] Wool Red
    [4] Kangaroo Black      [14] Long Brown       [24] Punky White      [34] Straight Gray
    [5] CapBack Blue        [15] Long Gray        [25] Short Black      [35] Straight Orange
    [6] CapBack Orange      [16] Long Red         [26] Short Blonde     [36] Straight Platinum
    [7] Conspiracist        [17] Long White       [27] Short Brown      [37] Straight Purple
    [8] Cop                 [18] Punky Black      [28] Short Gray       [38] Straight Red
    [9] CapFront Purple     [19] Punky Blonde     [29] Short Red        [39] Straight White
  5 - Glasses
    [0] None       [2] Nerd      [4] Pilot     [6] VR
    [1] Beetle     [3] Patch     [5] Surf
  6 - Lipstick Male
    [0] None
  6 - Lipstick Female
    [0] None      [2] Orange     [4] Purple
    [1] Green     [3] Pink       [5] Red
  7 - Smoking
    [0] None      [2] Cigarette
    [1] Cigar     [3] E-Cigarette

 */

pragma solidity 0.8.10;

import {ERC721Enumerable} from '../openzeppelin/ERC721Enumerable.sol';
import {ERC721} from '../openzeppelin/ERC721.sol';
import {IERC20} from '../openzeppelin/IERC20.sol';
import {IERC2981} from '../openzeppelin/IERC2981.sol';
import {IERC165} from '../openzeppelin/IERC165.sol';
import {SafeERC20} from '../openzeppelin/SafeERC20.sol';
import {IDescriptor} from './IDescriptor.sol';

contract Decentralists is IERC2981, ERC721Enumerable {
  using SafeERC20 for IERC20;

  // Minting price of each breed
  uint256 public constant MINT_PRICE_HUMAN = 0 ether;
  uint256 public constant MINT_PRICE_VAMPIRE = 0.15 ether;
  uint256 public constant MINT_PRICE_METAHUMAN = 0.05 ether;
  uint256 public constant MINT_PRICE_APE = 0.25 ether;

  // Minting price of each breed during presale
  uint256 private constant MINT_PRICE_PRESALE_VAMPIRE = 0.12 ether;
  uint256 private constant MINT_PRICE_PRESALE_METAHUMAN = 0.04 ether;
  uint256 private constant MINT_PRICE_PRESALE_APE = 0.2 ether;

  // Maximum total supply during presale
  uint24 private constant MAXIMUM_PRESALE_SUPPLY_VAMPIRE = 31;
  uint24 private constant MAXIMUM_PRESALE_SUPPLY_METAHUMAN = 21;
  uint24 private constant MAXIMUM_PRESALE_SUPPLY_APE = 53;

  // Maximum total supply of the collection
  uint24 public constant MAXIMUM_TOTAL_SUPPLY = 1000000;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_MALE_HUMAN = 495000;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_HUMAN = 495000;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_MALE_VAMPIRE = 1500;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_VAMPIRE = 1500;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_MALE_METAHUMAN = 3000;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_METAHUMAN = 3000;
  uint24 public constant MAXIMUM_TOTAL_SUPPLY_OF_APE = 1000;

  // Trait sizes
  uint256 private constant TRAIT_BASE_SIZE = 13;
  uint256 private constant TRAIT_NECKLACE_SIZE = 4;
  uint256 private constant TRAIT_FACIAL_MALE_SIZE = 25;
  uint256 private constant TRAIT_FACIAL_FEMALE_SIZE = 1;
  uint256 private constant TRAIT_EARRING_SIZE = 5;
  uint256 private constant TRAIT_HEAD_MALE_SIZE = 35;
  uint256 private constant TRAIT_HEAD_FEMALE_SIZE = 44;
  uint256 private constant TRAIT_GLASSES_SIZE = 7;
  uint256 private constant TRAIT_LIPSTICK_MALE_SIZE = 1;
  uint256 private constant TRAIT_LIPSTICK_FEMALE_SIZE = 6;
  uint256 private constant TRAIT_SMOKING_SIZE = 4;

  // Base trait separator for each breed
  uint256 private constant TRAIT_BASE_HUMAN_SEPARATOR = 8;
  uint256 private constant TRAIT_BASE_VAMPIRE_SEPARATOR = 10;
  uint256 private constant TRAIT_BASE_METAHUMAN_SEPARATOR = 12;
  uint256 private constant TRAIT_BASE_APE_SEPARATOR = 13;

  // Governance
  address public governance;
  address public emergencyAdmin;

  // Descriptor
  IDescriptor public descriptor;
  bool public isDescriptorLocked;

  // Royalties
  uint256 public royaltyBps;
  address public royaltyReceiver;

  struct Data {
    // Presale ends after 1 week
    uint40 presaleStartTime;
    // Emergency stop of the claiming process
    bool isStopped;
    // Decremental counters, from maximum total supply to zero
    uint24 count;
    uint24 femaleHumans;
    uint24 maleHumans;
    uint24 femaleVampires;
    uint24 maleVampires;
    uint24 femaleMetahumans;
    uint24 maleMetahumans;
    uint24 apes;
  }
  Data private data;

  // Combination of traits
  struct Combination {
    uint8 base;
    uint8 necklace;
    uint8 facial;
    uint8 earring;
    uint8 head;
    uint8 glasses;
    uint8 lipstick;
    uint8 smoking;
  }
  // Combinations: keccak256(combination) => tokenId
  mapping(bytes32 => uint256) private _combinationToId;
  // Combinations: tokenId => Combination
  mapping(uint256 => Combination) private _idToCombination;

  // Mapping of human minters
  mapping(address => bool) private _hasMintedHuman;

  /**
   * @dev Constructor
   * @param governance_ address of the governance
   * @param emergencyAdmin_ address of the emergency admin
   * @param descriptor_ address of the token descriptor
   * @param royaltyBps_ value of bps for royalties (e.g. 150 corresponds to 1.50%)
   * @param royaltyReceiver_ address of the royalties receiver
   * @param initialMintingRecipients_ array of recipients for the initial minting
   * @param initialMintingCombinations_ array of combinations for the initial minting
   */
  constructor(
    address governance_,
    address emergencyAdmin_,
    address descriptor_,
    uint256 royaltyBps_,
    address royaltyReceiver_,
    address[] memory initialMintingRecipients_,
    uint256[8][] memory initialMintingCombinations_
  ) ERC721('Decentralists', 'DCN') {
    governance = governance_;
    emergencyAdmin = emergencyAdmin_;
    descriptor = IDescriptor(descriptor_);
    royaltyBps = royaltyBps_;
    royaltyReceiver = royaltyReceiver_;

    // Decremental counters
    data.count = MAXIMUM_TOTAL_SUPPLY;
    data.femaleHumans = MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_HUMAN;
    data.maleHumans = MAXIMUM_TOTAL_SUPPLY_OF_MALE_HUMAN;
    data.femaleVampires = MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_VAMPIRE;
    data.maleVampires = MAXIMUM_TOTAL_SUPPLY_OF_MALE_VAMPIRE;
    data.femaleMetahumans = MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_METAHUMAN;
    data.maleMetahumans = MAXIMUM_TOTAL_SUPPLY_OF_MALE_METAHUMAN;
    data.apes = MAXIMUM_TOTAL_SUPPLY_OF_APE;

    // Initial minting
    unchecked {
      uint256 size = initialMintingRecipients_.length;
      for (uint256 i = 0; i < size; i++) {
        _claim(initialMintingCombinations_[i], initialMintingRecipients_[i]);
      }
    }
  }

  /**
   * @notice Mint a token with given traits (array of 8 values)
   * @param traits set of traits of the token
   */
  function claim(uint256[8] calldata traits) external payable {
    require(!data.isStopped, 'CLAIM_STOPPED');
    require(!isPresale() && data.presaleStartTime != 0, 'SALE_NOT_ACTIVE');
    require(_validateCombination(traits), 'INVALID_COMBINATION');
    require(_checkValue(traits[0], false), 'INCORRECT_VALUE');

    _claim(traits, msg.sender);
  }

  /**
   * @notice Mint a token with given traits (array of 8 values) during presale
   * @param traits set of traits of the token
   */
  function presaleClaim(uint256[8] calldata traits) external payable {
    require(!data.isStopped, 'CLAIM_STOPPED');
    require(isPresale() && data.presaleStartTime != 0, 'PRESALE_NOT_ACTIVE');
    require(_validateCombination(traits), 'INVALID_COMBINATION');
    require(!_humanBase(traits[0]), 'HUMANS_NOT_AVAILABLE');
    require(_checkValue(traits[0], true), 'INCORRECT_VALUE');

    // Check breed counter during presale
    if (_vampireBase(traits[0])) {
      require(
        totalFemaleVampiresSupply() + totalMaleVampiresSupply() < MAXIMUM_PRESALE_SUPPLY_VAMPIRE,
        'NO_CLAIMS_AVAILABLE'
      );
    } else if (_metahumanBase(traits[0])) {
      require(
        totalFemaleMetahumansSupply() + totalMaleMetahumansSupply() <
          MAXIMUM_PRESALE_SUPPLY_METAHUMAN,
        'NO_CLAIMS_AVAILABLE'
      );
    } else {
      require(totalApesSupply() < MAXIMUM_PRESALE_SUPPLY_APE, 'NO_CLAIMS_AVAILABLE');
    }

    _claim(traits, msg.sender);
  }

  /**
   * @notice Returns whether the combination given is available or not
   * @param traits set of traits of the combination
   * @return true if the combination is available, false otherwise
   */
  function isCombinationAvailable(uint256[8] calldata traits) external view returns (bool) {
    require(_validateCombination(traits), 'INVALID_COMBINATION');
    bytes32 hashedCombination = keccak256(
      abi.encodePacked(
        traits[0], // base
        traits[1], // necklace
        traits[2], // facial
        traits[3], // earring
        traits[4], // head
        traits[5], // glasses
        traits[6], // lipstick
        traits[7] // smoking
      )
    );
    return _combinationToId[hashedCombination] == 0;
  }

  /**
   * @notice Returns whether the combination given is valid or not
   * @param traits set of traits of the combination to validate
   * @return true if the combination is valid, false otherwise
   */
  function isCombinationValid(uint256[8] calldata traits) external pure returns (bool) {
    return _validateCombination(traits);
  }

  /**
   * @notice Returns whether the presale is active or not (1 week duration)
   * @return true if the presale is active, false otherwise
   */
  function isPresale() public view returns (bool) {
    return block.timestamp <= data.presaleStartTime + 1 weeks;
  }

  /**
   * @notice Returns whether the claiming process is stopped or not
   * @return true if the claiming process is stop, false otherwise
   */
  function isEmergencyStopped() external view returns (bool) {
    return data.isStopped;
  }

  /**
   * @notice Returns the token id of a given set of traits
   * @param traits set of traits of the token
   * @return token id
   */
  function getTokenId(uint256[8] calldata traits) external view returns (uint256) {
    bytes32 hashedCombination = keccak256(
      abi.encodePacked(
        traits[0], // base
        traits[1], // necklace
        traits[2], // facial
        traits[3], // earring
        traits[4], // head
        traits[5], // glasses
        traits[6], // lipstick
        traits[7] // smoking
      )
    );
    require(_combinationToId[hashedCombination] != 0, 'NOT_EXISTS');
    return _combinationToId[hashedCombination];
  }

  /**
   * @notice Returns the set of traits given a token id
   * @param tokenId the id of the token
   * @return traits array
   */
  function getTraits(uint256 tokenId) external view returns (uint256[8] memory) {
    require(_exists(tokenId), 'NOT_EXISTS');
    return _getTraits(tokenId);
  }

  /**
   * @notice Returns the set of traits given a token id
   * @param tokenId the id of the token
   * @return traits array
   */
  function _getTraits(uint256 tokenId) internal view returns (uint256[8] memory traits) {
    Combination memory c = _idToCombination[tokenId];
    traits[0] = c.base;
    traits[1] = c.necklace;
    traits[2] = c.facial;
    traits[3] = c.earring;
    traits[4] = c.head;
    traits[5] = c.glasses;
    traits[6] = c.lipstick;
    traits[7] = c.smoking;
  }

  /**
   * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token
   * @param tokenId token id
   * @return uri of the given `tokenId`
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'NOT_EXISTS');
    return descriptor.tokenURI(_getTraits(tokenId));
  }

  /**
   * @notice Returns whether the given address of the user has already minted a human or not
   * @param user address of the user
   * @return true if `user` has minted a human, false otherwise
   */
  function hasMintedHuman(address user) external view returns (bool) {
    return _hasMintedHuman[user];
  }

  /**
   * @notice Returns the total amount of female human tokens
   * @return total supply of female humans
   */
  function totalFemaleHumansSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_HUMAN - data.femaleHumans;
  }

  /**
   * @notice Returns the total amount of male human tokens
   * @return total supply of male humans
   */
  function totalMaleHumansSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_MALE_HUMAN - data.maleHumans;
  }

  /**
   * @notice Returns the total amount of female vampire tokens
   * @return total supply of female vampires
   */
  function totalFemaleVampiresSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_VAMPIRE - data.femaleVampires;
  }

  /**
   * @notice Returns the total amount of male vampire tokens
   * @return total supply of male vampires
   */
  function totalMaleVampiresSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_MALE_VAMPIRE - data.maleVampires;
  }

  /**
   * @notice Returns the total amount of female metahuman tokens
   * @return total supply of female metahumans
   */
  function totalFemaleMetahumansSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_FEMALE_METAHUMAN - data.femaleMetahumans;
  }

  /**
   * @notice Returns the total amount of male metahuman tokens
   * @return total supply of male metahumans
   */
  function totalMaleMetahumansSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_MALE_METAHUMAN - data.maleMetahumans;
  }

  /**
   * @notice Returns the total amount of ape tokens
   * @return total supply of apes
   */
  function totalApesSupply() public view returns (uint256) {
    return MAXIMUM_TOTAL_SUPPLY_OF_APE - data.apes;
  }

  /**
   * @notice Returns the starting time of the presale (0 if it did not start yet)
   * @return starting time of the presale
   */
  function presaleStartTime() external view returns (uint256) {
    return uint256(data.presaleStartTime);
  }

  /**
   * @notice Returns how much royalty is owed and to whom, based on the sale price
   * @param tokenId token id of the NFT asset queried for royalty information
   * @param salePrice sale price of the NFT asset specified by `tokenId`
   * @return receiver address of the royalty payment
   * @return amount of the royalty payment for `salePrice`
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override(IERC2981)
    returns (address, uint256)
  {
    require(_exists(tokenId), 'NOT_EXISTS');
    return (royaltyReceiver, (salePrice * royaltyBps) / 10000);
  }

  /**
   * @dev Checks if the contract supports the given interface
   * @param interfaceId The identifier of the interface
   * @return True if the interface is supported, false otherwise
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, IERC165)
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @notice Activate the presale
   * @dev Only callable by governance
   */
  function startPresale() external onlyGovernance {
    require(data.presaleStartTime == 0, 'PRESALE_ALREADY_STARTED');
    data.presaleStartTime = uint40(block.timestamp);
    emit PresaleStart();
  }

  /**
   * @notice Pull ETH funds from the contract to the given recipient
   * @dev Only callable by governance
   * @param recipient address to transfer the funds to
   * @param amount amount of funds to transfer
   */
  function pullFunds(address recipient, uint256 amount) external onlyGovernance {
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'UNABLE_TO_PULL');
    emit FundsWithdrawal(recipient, amount);
  }

  /**
   * @notice Pull ERC20 token funds from the contract to the given recipient
   * @dev Only callable by governance
   * @param asset address of the ERC20 token to transfer
   * @param recipient address to transfer the funds to
   * @param amount amount of funds to transfer
   */
  function pullTokens(
    address asset,
    address recipient,
    uint256 amount
  ) external onlyGovernance {
    IERC20(asset).safeTransfer(recipient, amount);
  }

  /**
   * @notice Update the governance address
   * @dev Only callable by governance
   * @param newGovernance address of the new governance
   */
  function setGovernance(address newGovernance) external onlyGovernance {
    address oldGovernance = governance;
    governance = newGovernance;

    emit GovernanceUpdate(oldGovernance, newGovernance);
  }

  /**
   * @notice Update the descriptor address
   * @dev Only callable by governance when descriptor is not locked
   * @param newDescriptor address of the new descriptor
   */
  function setDescriptor(address newDescriptor) external onlyGovernance whenDescriptorNotLocked {
    address oldDescriptor = address(descriptor);
    descriptor = IDescriptor(newDescriptor);

    emit DescriptorUpdate(oldDescriptor, newDescriptor);
  }

  /**
   * @notice Lock the ability to update the descriptor address
   * @dev Only callable by governance when descriptor is not locked
   */
  function lockDescriptor() external onlyGovernance whenDescriptorNotLocked {
    isDescriptorLocked = true;

    emit DescriptorLock(address(descriptor));
  }

  /**
   * @notice Update the royalty basis points (e.g. a value of 150 corresponds to 1.50%)
   * @dev Only callable by governance
   * @param newRoyaltyBps value of the new royalty bps
   */
  function setRoyaltyBps(uint256 newRoyaltyBps) external onlyGovernance {
    uint256 oldRoyaltyBps = royaltyBps;
    royaltyBps = newRoyaltyBps;

    emit RoyaltyBpsUpdate(oldRoyaltyBps, newRoyaltyBps);
  }

  /**
   * @notice Update the royalty receiver
   * @dev Only callable by governance
   * @param newRoyaltyReceiver address of the new royalty receiver
   */
  function setRoyaltyReceiver(address newRoyaltyReceiver) external onlyGovernance {
    address oldRoyaltyReceiver = royaltyReceiver;
    royaltyReceiver = newRoyaltyReceiver;

    emit RoyaltyReceiverUpdate(oldRoyaltyReceiver, newRoyaltyReceiver);
  }

  /**
   * @notice Stops the claiming process of the contract in case of emergency
   * @dev Only callable by emergency admin
   * @param isStopped true to stop the claiming process, false otherwise
   */
  function emergencyStop(bool isStopped) external {
    require(msg.sender == emergencyAdmin, 'ONLY_BY_EMERGENCY_ADMIN');
    data.isStopped = isStopped;

    emit EmergencyStop(isStopped);
  }

  /**
   * @notice Update the emergency admin address
   * @dev Only callable by emergency admin
   * @param newEmergencyAdmin address of the new emergency admin
   */
  function setEmergencyAdmin(address newEmergencyAdmin) external {
    require(msg.sender == emergencyAdmin, 'ONLY_BY_EMERGENCY_ADMIN');

    address oldEmergencyAdmin = emergencyAdmin;
    emergencyAdmin = newEmergencyAdmin;

    emit EmergencyAdminUpdate(oldEmergencyAdmin, newEmergencyAdmin);
  }

  /**
   * @notice Mint a token to the receiver
   * @param traits set of traits of the token
   * @param receiver receiver address
   */
  function _claim(uint256[8] memory traits, address receiver) internal {
    require(msg.sender == tx.origin, 'ONLY_EOA');
    require(data.count > 0, 'NO_CLAIMS_AVAILABLE');

    uint256 base = traits[0];
    bytes32 hashedCombination = keccak256(
      abi.encodePacked(
        base, // base
        traits[1], // necklace
        traits[2], // facial
        traits[3], // earring
        traits[4], // head
        traits[5], // glasses
        traits[6], // lipstick
        traits[7] // smoking
      )
    );
    require(_combinationToId[hashedCombination] == 0, 'ALREADY_EXISTS');
    if (_humanBase(base)) {
      require(!_hasMintedHuman[msg.sender], 'INVALID_HUMAN_MINTER');
      _hasMintedHuman[msg.sender] = true;
    }

    // TokenId (0 is reserved)
    uint256 tokenId = MAXIMUM_TOTAL_SUPPLY - data.count + 1;

    // Update breed counter
    if (_humanBase(base)) {
      if (_isMale(base)) {
        data.maleHumans--;
      } else {
        data.femaleHumans--;
      }
    } else if (_vampireBase(base)) {
      if (_isMale(base)) {
        data.maleVampires--;
      } else {
        data.femaleVampires--;
      }
    } else if (_metahumanBase(base)) {
      if (_isMale(base)) {
        data.maleMetahumans--;
      } else {
        data.femaleMetahumans--;
      }
    } else {
      data.apes--;
    }
    data.count--;

    // Traits
    _combinationToId[hashedCombination] = tokenId;
    _idToCombination[tokenId] = Combination({
      base: uint8(base),
      necklace: uint8(traits[1]),
      facial: uint8(traits[2]),
      earring: uint8(traits[3]),
      head: uint8(traits[4]),
      glasses: uint8(traits[5]),
      lipstick: uint8(traits[6]),
      smoking: uint8(traits[7])
    });

    _mint(receiver, tokenId);

    emit DecentralistMint(tokenId, receiver, traits);
  }

  /**
   * @notice Check the transaction value is correct given a base and whether the presale is active
   * @param base value of the base trait
   * @param inPresale true if presale is active, false otherwise
   * @return true if the transaction value is correct, false otherwise
   */
  function _checkValue(uint256 base, bool inPresale) internal view returns (bool) {
    if (_humanBase(base)) {
      return msg.value == MINT_PRICE_HUMAN;
    } else if (_vampireBase(base)) {
      return inPresale ? msg.value == MINT_PRICE_PRESALE_VAMPIRE : msg.value == MINT_PRICE_VAMPIRE;
    } else if (_metahumanBase(base)) {
      return
        inPresale ? msg.value == MINT_PRICE_PRESALE_METAHUMAN : msg.value == MINT_PRICE_METAHUMAN;
    } else if (_apeBase(base)) {
      return inPresale ? msg.value == MINT_PRICE_PRESALE_APE : msg.value == MINT_PRICE_APE;
    } else {
      return false;
    }
  }

  /**
   * @notice Check whether a set of traits is a valid combination or not
   * @dev Even numbers of base trait corresponds to male
   * @param traits set of traits of the token
   * @return true if it is a valid combination, false otherwise
   */
  function _validateCombination(uint256[8] calldata traits) internal pure returns (bool) {
    bool isMale = _isMale(traits[0]);
    if (
      isMale &&
      traits[0] < TRAIT_BASE_SIZE &&
      traits[1] < TRAIT_NECKLACE_SIZE &&
      traits[2] < TRAIT_FACIAL_MALE_SIZE &&
      traits[3] < TRAIT_EARRING_SIZE &&
      traits[4] < TRAIT_HEAD_MALE_SIZE &&
      traits[5] < TRAIT_GLASSES_SIZE &&
      traits[6] < TRAIT_LIPSTICK_MALE_SIZE &&
      traits[7] < TRAIT_SMOKING_SIZE
    ) {
      return true;
    } else if (
      !isMale &&
      traits[0] < TRAIT_BASE_SIZE &&
      traits[1] < TRAIT_NECKLACE_SIZE &&
      traits[2] < TRAIT_FACIAL_FEMALE_SIZE &&
      traits[3] < TRAIT_EARRING_SIZE &&
      traits[4] < TRAIT_HEAD_FEMALE_SIZE &&
      traits[5] < TRAIT_GLASSES_SIZE &&
      traits[6] < TRAIT_LIPSTICK_FEMALE_SIZE &&
      traits[7] < TRAIT_SMOKING_SIZE
    ) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice Returns true if the base trait corresponds to human breed
   * @param base value of the base trait
   * @return True if the base corresponds to human breed, false otherwise
   */
  function _humanBase(uint256 base) internal pure returns (bool) {
    return base < TRAIT_BASE_HUMAN_SEPARATOR;
  }

  /**
   * @notice Returns true if the base trait corresponds to vampire breed
   * @param base value of the base trait
   * @return True if the base corresponds to vampire breed, false otherwise
   */
  function _vampireBase(uint256 base) internal pure returns (bool) {
    return base >= TRAIT_BASE_HUMAN_SEPARATOR && base < TRAIT_BASE_VAMPIRE_SEPARATOR;
  }

  /**
   * @notice Returns true if the base trait corresponds to metahuman breed
   * @param base value of the base trait
   * @return True if the base corresponds to metahuman breed, false otherwise
   */
  function _metahumanBase(uint256 base) internal pure returns (bool) {
    return base >= TRAIT_BASE_VAMPIRE_SEPARATOR && base < TRAIT_BASE_METAHUMAN_SEPARATOR;
  }

  /**
   * @notice Returns true if the base trait corresponds to ape breed
   * @param base value of the base trait
   * @return True if the base corresponds to ape breed, false otherwise
   */
  function _apeBase(uint256 base) internal pure returns (bool) {
    return base >= TRAIT_BASE_METAHUMAN_SEPARATOR && base < TRAIT_BASE_APE_SEPARATOR;
  }

  /**
   * @notice Returns true if the base trait corresponds to male sex
   * @param base value of the base trait
   * @return True if the base corresponds to male sex, false otherwise
   */
  function _isMale(uint256 base) internal pure returns (bool) {
    return base % 2 == 0;
  }

  /**
   * @dev Hook that is called before any transfer of tokens
   * @param from origin address of the transfer
   * @param to recipient address of the transfer
   * @param tokenId id of the token to transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Functions marked by this modifier can only be called when descriptor is not locked
   **/
  modifier whenDescriptorNotLocked() {
    require(!isDescriptorLocked, 'DESCRIPTOR_LOCKED');
    _;
  }

  /**
   * @dev Functions marked by this modifier can only be called by governance
   **/
  modifier onlyGovernance() {
    require(msg.sender == governance, 'ONLY_BY_GOVERNANCE');
    _;
  }

  /**
   * @dev Emitted when a new token is minted
   * @param tokenId token id
   * @param recipient address of the recipient of the token
   * @param traits set of traits of the token
   */
  event DecentralistMint(uint256 indexed tokenId, address indexed recipient, uint256[8] traits);

  /**
   * @dev Emitted when the presale starts
   */
  event PresaleStart();

  /**
   * @dev Emitted when funds are withdraw
   * @param recipient address of the recipient of the funds
   * @param amount amount of the funds withdraw
   */
  event FundsWithdrawal(address indexed recipient, uint256 amount);

  /**
   * @dev Emitted when the governance address is updated
   * @param oldGovernance address of the old governance
   * @param newGovernance address of the new governance
   */
  event GovernanceUpdate(address indexed oldGovernance, address indexed newGovernance);

  /**
   * @dev Emitted when the emergency admin stops the claiming process
   * @param isStopped true if it is stopped, false otherwise
   */
  event EmergencyStop(bool isStopped);

  /**
   * @dev Emitted when the emergency admin address is updated
   * @param oldEmergencyAdmin address of the old emergency admin
   * @param newEmergencyAdmin address of the new emergency admin
   */
  event EmergencyAdminUpdate(address indexed oldEmergencyAdmin, address indexed newEmergencyAdmin);

  /**
   * @dev Emitted when the descriptor address is updated
   * @param oldDescriptor address of the old descriptor
   * @param newDescriptor address of the new descriptor
   */
  event DescriptorUpdate(address indexed oldDescriptor, address indexed newDescriptor);

  /**
   * @dev Emitted when the descriptor is locked
   * @param descriptor address of the descriptor
   */
  event DescriptorLock(address indexed descriptor);

  /**
   * @dev Emitted when the royalty bps value is updated
   * @param oldRoyaltyBps old value of the royalty bps
   * @param newRoyaltyBps new value of the royalty bps
   */
  event RoyaltyBpsUpdate(uint256 oldRoyaltyBps, uint256 newRoyaltyBps);

  /**
   * @dev Emitted when the royalty receiver is updated
   * @param oldRoyaltyReceiver address of the old royalty receiver
   * @param newRoyaltyReceiver address of the new royalty receiver
   */
  event RoyaltyReceiverUpdate(
    address indexed oldRoyaltyReceiver,
    address indexed newRoyaltyReceiver
  );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
pragma solidity 0.8.10;

interface IDescriptor {
  function tokenURI(uint256[8] calldata) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
pragma solidity 0.8.10;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
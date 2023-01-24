/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

// Version 1.0 with hardcoded values
contract DistributeRewards is Ownable {
    using Address for address;
    using SafeMath for uint;
    
    event RewardsTransferred(address holder, uint amount);
    event RewardRateChanged(address holder, uint amount);
    
    // ============================= CONTRACT VARIABLES ==============================
    
    // Trusted token contract address
    address public constant TRUSTED_DYP_ADDRESS = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;
    address public constant TRUSTED_IDYP_ADDRESS = 0xBD100d061E120b2c67A24453CF6368E63f1Be056;
    address public constant TRUSTED_WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Distribution Addresses
    address public constant NFT_ADDRESS = 0xEe425BbbEC5e9Bf4a59a1c19eFff522AD8b7A47A;
    address public constant STAKING_7_ADDRESS = 0xeb7dd6B50dB34f7ff14898D0Be57A99A9F158C4D;
    address public constant STAKING_30_ADDRESS = 0xD4bE7a106ed193BEe39D6389a481ec76027B2660;
    address public constant STAKING_15_ADDRESS = 0x50014432772b4123D04181727C6EdEAB34F5F988;

    // Rate for each Address
    uint public RATE_NFT = 1250000000000000000;
    uint public RATE_STAKING_7 = 1700e18;
    uint public RATE_STAKING_30 = 23000e18;
    uint public RATE_STAKING_15 = 35000e18;

    // Distribution Time of each rewards
    uint public DISTRIBUTION_TIME = 7 days;

    bool public isEmergency = false;

    // ========================= END CONTRACT VARIABLES ==============================

    mapping (address => uint) public sendTime;
    
    constructor() public {
        sendTime[NFT_ADDRESS] = now;
        sendTime[STAKING_7_ADDRESS] = now;
        sendTime[STAKING_30_ADDRESS] = now;
        sendTime[STAKING_15_ADDRESS] = now;
    }

    modifier notDuringEmergency() {
        require(!isEmergency, "Cannot execute during emergency!");
        _;
    }
    
    function distributeRewardNft() external notDuringEmergency {

        require(now.sub(sendTime[NFT_ADDRESS]) > DISTRIBUTION_TIME, "Tokens already distributed for this week");
        require(Token(TRUSTED_WETH_ADDRESS).transfer(NFT_ADDRESS, RATE_NFT), "Transfer failed!");

        sendTime[NFT_ADDRESS] = now;
        emit RewardsTransferred(NFT_ADDRESS, RATE_NFT);
    }

    function distributeRewardStaking7() external notDuringEmergency {

        require(now.sub(sendTime[STAKING_7_ADDRESS]) > DISTRIBUTION_TIME, "Tokens already distributed for this week");
        require(Token(TRUSTED_DYP_ADDRESS).transfer(STAKING_7_ADDRESS, RATE_STAKING_7), "Transfer failed!");

        sendTime[STAKING_7_ADDRESS] = now;
        emit RewardsTransferred(STAKING_7_ADDRESS, RATE_STAKING_7);
    }

    function distributeRewardStaking30() external notDuringEmergency {

        require(now.sub(sendTime[STAKING_30_ADDRESS]) > DISTRIBUTION_TIME, "Tokens already distributed for this week");
        require(Token(TRUSTED_IDYP_ADDRESS).transfer(STAKING_30_ADDRESS, RATE_STAKING_30), "Transfer failed!");

        sendTime[STAKING_30_ADDRESS] = now;
        emit RewardsTransferred(STAKING_30_ADDRESS, RATE_STAKING_30);
    }

    function distributeRewardStaking15() external notDuringEmergency {

        require(now.sub(sendTime[STAKING_15_ADDRESS]) > DISTRIBUTION_TIME, "Tokens already distributed for this week");
        require(Token(TRUSTED_IDYP_ADDRESS).transfer(STAKING_15_ADDRESS, RATE_STAKING_15), "Transfer failed!");

        sendTime[STAKING_15_ADDRESS] = now;
        emit RewardsTransferred(STAKING_15_ADDRESS, RATE_STAKING_15);
    }
    
    function setRateNft(uint newRewardRate) public onlyOwner {
        RATE_NFT = newRewardRate;
        emit RewardRateChanged(NFT_ADDRESS, RATE_NFT);
    }

    function setRateStaking7(uint newRewardRate) public onlyOwner {
        RATE_STAKING_7 = newRewardRate;
        emit RewardRateChanged(STAKING_7_ADDRESS, RATE_STAKING_7);
    }

    function setRateStaking30(uint newRewardRate) public onlyOwner {
        RATE_STAKING_30 = newRewardRate;
        emit RewardRateChanged(STAKING_30_ADDRESS, RATE_STAKING_30);
    }

    function setRateStaking15(uint newRewardRate) public onlyOwner {
        RATE_STAKING_15 = newRewardRate;
        emit RewardRateChanged(STAKING_15_ADDRESS, RATE_STAKING_15);
    }
    
    function transferAnyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (Token(tokenAddress).transfer(recipient, amount), "Transfer failed!");
    }
    
    function transferAnyLegacyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }

    /*
    * Pause Distrbution if active, make active if paused
    */
    function flipEmergency() public onlyOwner {
        isEmergency = !isEmergency;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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


pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

abstract contract SQUIRES {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

	function upgradeTokenFromQuesting(uint256 tokenId,  uint stengthUpgrade, uint wisdomUpgrade, uint luckUpgrade, uint faithUpgrade) public virtual;

    function squireTypeByTokenId(uint256 tokenId) public view virtual returns (uint);

    function setApprovalForAll(address operator, bool _approved) external virtual;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

abstract contract RINGS {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function safeMint(address to) public virtual;
}

abstract contract POTIONS {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function safeMint(address to) public virtual;
}

abstract contract TRINKETS {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256 balance);

    function safeMint(address to) public virtual;
}

contract SquireQuesting is Ownable {
    using SafeERC20 for IERC20;

    SQUIRES public squires = SQUIRES(squiresContract);
    RINGS public rings = RINGS(ringsContract);
    POTIONS public potions = POTIONS(potionsContract);
    TRINKETS public trinkets = TRINKETS(trinketsContract);

    address public squiresContract;
    address public ringsContract;
    address public potionsContract;
    address public trinketsContract;

    //$FIEF token
	address public fiefToken;
    IERC20 fief = IERC20(fiefToken);

    mapping(address => uint256[]) private addressToSquireForest;
    mapping(address => uint256[]) private addressToSquireMountain;
    mapping(address => uint256[]) private addressToSquireCavern;
    mapping(address => uint256[]) private addressToSquireAlter;
    mapping(address => uint256) private leaveForestIndex;

    mapping (address => uint256) public addressToAmountClaimed;
    mapping (uint => uint256) public squireToAmountClaimed;

    bool public questingActive = false;
    bool public leavingquestingActive = false;

    //forest settings
    uint FtotalProbability = 1000;
    uint Fprobability1 = 750; uint Freturn1 = 1; //fief
    uint Fprobability2 = 200; uint Freturn2 = 2; //fief
    uint Fprobability3 = 45;  uint Freturn3 = 3; //fief
    uint Fprobability4 = 5;  uint Freturn4 = 5;  //fief
    uint Fupgrade = 1;

    uint FprobabilityUpgrade = 200;
    uint FprobabilityUpgradeT = 350;

     //moutain settings
    uint MtotalProbability = 1000;
    uint Mprobability1 = 690; uint Mreturn1 = 1; //fief
    uint Mprobability2 = 250; 
    uint Mprobability3 = 60;   
    uint Mupgrade = 1;

    uint MprobabilityUpgrade = 200;
    uint MprobabilityUpgradeT = 350;

    //cavern settings
    uint CtotalProbability = 1000;
    uint Cprobability1 = 650; uint Creturn1 = 1; //fief
    uint Cprobability2 = 300; 
    uint Cprobability3 = 50;   
    uint Cupgrade = 1;

    uint CprobabilityUpgrade = 200;
    uint CprobabilityUpgradeT = 350;

    //altar settings
    uint AtotalProbability = 1000;
    uint Aprobability1 = 590; uint Areturn1 = 1; //fief
    uint Aprobability2 = 400; //stat increase
    uint Aprobability3 = 10;  //doubles
    uint Aupgrade = 1;

    constructor() {}

    function flipQuestingActiveState() public onlyOwner {
        questingActive = !questingActive;
    }

     function flipLeavingQuestingActiveState() public onlyOwner {
        leavingquestingActive = !leavingquestingActive;
    } 


    function questForest(uint256[] memory squireIds) public {
        require(questingActive, "Questing must be active");
        require(squireIds.length >= 1, "1 or more Squires must go on a quest");

        for (uint256 i = 0; i < squireIds.length; i++) {
            require(squires.ownerOf(squireIds[i]) == msg.sender);
        }
        
        for (uint256 i = 0; i < squireIds.length; i++) {
            squires.transferFrom(msg.sender, address(this), squireIds[i]);
            addressToSquireForest[msg.sender].push(squireIds[i]);
        }
    }

    function questMoutain(uint256[] calldata squireIds) public {
        require(questingActive, "Questing must be active");
        require(squireIds.length >= 1, "1 or more Squires must go on a quest");

        for (uint256 i = 0; i < squireIds.length; i++) {
            require(squires.ownerOf(squireIds[i]) == msg.sender);
        }
        for (uint256 i = 0; i < squireIds.length; i++) {
            squires.transferFrom(msg.sender, address(this), squireIds[i]);
            addressToSquireMountain[msg.sender].push(squireIds[i]);
        }
    }

    function questCavern(uint256[] memory squireIds) public {
        require(questingActive, "Questing must be active");
        require(squireIds.length >= 1, "1 or more Squires must go on a quest");

        for (uint256 i = 0; i < squireIds.length; i++) {
            require(squires.ownerOf(squireIds[i]) == msg.sender);
        }
        for (uint256 i = 0; i < squireIds.length; i++) {
            squires.transferFrom(msg.sender, address(this), squireIds[i]);
            addressToSquireCavern[msg.sender].push(squireIds[i]);
        }
    }

    function questAltar(uint256[] memory squireIds) public {
        require(questingActive, "Questing must be active");
        require(squireIds.length >= 1, "1 or more Squires must go on a quest");

        for (uint256 i = 0; i < squireIds.length; i++) {
            require(squires.ownerOf(squireIds[i]) == msg.sender);
        }
        for (uint256 i = 0; i < squireIds.length; i++) {
            squires.transferFrom(msg.sender, address(this), squireIds[i]);
            addressToSquireAlter[msg.sender].push(squireIds[i]);
        }
    }

    function leaveForest() public {
        require(leavingquestingActive, "leaving quests is not active");
        require(addressToSquireForest[msg.sender].length > 0);
        require(leaveForestIndex[msg.sender] < addressToSquireForest[msg.sender].length);

        uint256[] memory squiresToLeaveForest = addressToSquireForest[msg.sender];

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
            squires.transferFrom(address(this), msg.sender, squiresToLeaveForest[i]);
        if(random(FtotalProbability) <= Fprobability1){
            SafeERC20.safeApprove(fief, address(this), Freturn1); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Freturn1);
            addressToAmountClaimed[msg.sender] += Freturn1;
            squireToAmountClaimed[i] += Freturn1;
        }
        else if(random(FtotalProbability) > Fprobability1 && random(FtotalProbability) <= Fprobability1 + Fprobability2){
            SafeERC20.safeApprove(fief, address(this), Freturn2); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Freturn2);
            addressToAmountClaimed[msg.sender] += Freturn2;
            squireToAmountClaimed[i] += Freturn2;
        }
         else if(random(FtotalProbability) > Fprobability1 + Fprobability2 && random(FtotalProbability) <= Fprobability1 + Fprobability2 + Fprobability3){
            SafeERC20.safeApprove(fief, address(this), Freturn3); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Freturn3);
            addressToAmountClaimed[msg.sender] += Freturn3;
            squireToAmountClaimed[i] += Freturn3;
        }
        else{
            SafeERC20.safeApprove(fief, address(this), Freturn4); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Freturn4); 
            addressToAmountClaimed[msg.sender] += Freturn4;
            squireToAmountClaimed[i] += Freturn4;
        }
        }
        leaveForestIndex[msg.sender] += squiresToLeaveForest.length;
   
        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {

           if(random(FtotalProbability) <= FprobabilityUpgrade){
         
                if(random(4) == 1){
                    //strength
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, 0, 0, 0);
                    }
                else if(random(4) == 2){
                    //wisdom
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, Fupgrade, 0, 0);
                    }
                else if(random(4) == 3){
                    //luck
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, Fupgrade, 0);
                    }
                else if(random(4) == 4){
                    //faith
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, 0, Fupgrade);
                    }
                else{
                    return;
                    }
                }
           }
    }

      function leaveMoutain() public {
        require(leavingquestingActive, "leaving quests is not active");
        require(addressToSquireForest[msg.sender].length > 0);
        require(leaveForestIndex[msg.sender] < addressToSquireForest[msg.sender].length);

        uint256[] memory squiresToLeaveForest = addressToSquireForest[msg.sender];

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
            squires.transferFrom(address(this), msg.sender, squiresToLeaveForest[i]);
            SafeERC20.safeApprove(fief, address(this), Mreturn1); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Mreturn1);
            addressToAmountClaimed[msg.sender] += Mreturn1;
            squireToAmountClaimed[i] += Mreturn1;
        }
        leaveForestIndex[msg.sender] += squiresToLeaveForest.length;

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
           if(random(MtotalProbability) <= Mprobability1){
            
           } 
           else if(random(MtotalProbability) <= Mprobability1 + Mprobability2 && random(MtotalProbability) > Mprobability1){
                rings.safeMint(msg.sender);
           }
           else{
                trinkets.safeMint(msg.sender);
           }
        }
   
        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {

           if(random(MtotalProbability) <= MprobabilityUpgrade){
         
                if(random(4) == 1){
                    //strength
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, 0, 0, 0);
                    }
                else if(random(4) == 2){
                    //wisdom
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, Fupgrade, 0, 0);
                    }
                else if(random(4) == 3){
                    //luck
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, Fupgrade, 0);
                    }
                else if(random(4) == 4){
                    //faith
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, 0, Fupgrade);
                    }
                else{
                    return;
                    }
                }
            }
    }

      function leaveCavern() public {
        require(leavingquestingActive, "leaving quests is not active");
        require(addressToSquireForest[msg.sender].length > 0);
        require(leaveForestIndex[msg.sender] < addressToSquireForest[msg.sender].length);

        uint256[] memory squiresToLeaveForest = addressToSquireForest[msg.sender];

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
            squires.transferFrom(address(this), msg.sender, squiresToLeaveForest[i]);
            SafeERC20.safeApprove(fief, address(this), Freturn1); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Freturn1);
            addressToAmountClaimed[msg.sender] += Freturn1;
            squireToAmountClaimed[i] += Freturn1;
        }
        leaveForestIndex[msg.sender] += squiresToLeaveForest.length;

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
           if(random(CtotalProbability) <= Cprobability1){
            
           } 
           else if(random(CtotalProbability) <= Cprobability1 + Cprobability2 && random(CtotalProbability) > Cprobability1){
                potions.safeMint(msg.sender);
           }
           else{
                rings.safeMint(msg.sender);
           }
        }
   
        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {

           if(random(CtotalProbability) <= CprobabilityUpgrade){
         
                if(random(4) == 1){
                    //strength
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, 0, 0, 0);
                    }
                else if(random(4) == 2){
                    //wisdom
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, Fupgrade, 0, 0);
                    }
                else if(random(4) == 3){
                    //luck
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, Fupgrade, 0);
                    }
                else if(random(4) == 4){
                    //faith
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, 0, Fupgrade);
                    }
                else{
                    return;
                    }
                }
            }
        }

      function leaveAltar() public {
        require(leavingquestingActive, "leaving quests is not active");
        require(addressToSquireForest[msg.sender].length > 0);
        require(leaveForestIndex[msg.sender] < addressToSquireForest[msg.sender].length);

        uint256[] memory squiresToLeaveForest = addressToSquireForest[msg.sender];

        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {
            squires.transferFrom(address(this), msg.sender, squiresToLeaveForest[i]);
            SafeERC20.safeApprove(fief, address(this), Areturn1); 
            SafeERC20.safeTransferFrom(fief, address(this), msg.sender, Areturn1);
            addressToAmountClaimed[msg.sender] += Areturn1;
            squireToAmountClaimed[i] += Areturn1;
        }
        leaveForestIndex[msg.sender] += squiresToLeaveForest.length;
   
        for (uint256 i = leaveForestIndex[msg.sender]; i < squiresToLeaveForest.length; i++) {

            if(random(AtotalProbability) <= Aprobability3){ //1%
         
                if(random(4) == 1){
                    //strength + wisdom
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, Fupgrade, 0, 0);
                    }
                else if(random(4) == 2){
                    //wisdom + luck
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, Fupgrade, Fupgrade, 0);
                    }
                else if(random(4) == 3){
                    //luck + faith
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, Fupgrade, Fupgrade);
                    }
                else if(random(4) == 4){
                    //faith + strenfth
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, 0, 0, Fupgrade);
                    }
                else{
                    return;
                    }
                }

           else if(random(AtotalProbability) <= Aprobability2){ //40%
         
                if(random(4) == 1){
                    //strength
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], Fupgrade, 0, 0, 0);
                    }
                else if(random(4) == 2){
                    //wisdom
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, Fupgrade, 0, 0);
                    }
                else if(random(4) == 3){
                    //luck
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, Fupgrade, 0);
                    }
                else if(random(4) == 4){
                    //faith
                    squires.upgradeTokenFromQuesting(squiresToLeaveForest[i], 0, 0, 0, Fupgrade);
                    }
                else{
                    return;
                    }
                }
            }
    }

    //generate random number for squireTypes
 	function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number + 1;
    }

    //set contracts
    function setSquiresContract(address _squiresContract) public onlyOwner{
     squiresContract = _squiresContract;
    }
    function setRingsContract(address _ringsContract) public onlyOwner{
     ringsContract = _ringsContract;
    }
    function setPotionsContract(address _potionsContract) public onlyOwner{
     potionsContract = _potionsContract;
    }
    function setTrinketsContract(address _trinketsContract) public onlyOwner{
     trinketsContract = _trinketsContract;
    }
    
    //set Fief Address
	function setFIEFTokenAddress(address _address) external onlyOwner {
		fiefToken = _address;
	}

}
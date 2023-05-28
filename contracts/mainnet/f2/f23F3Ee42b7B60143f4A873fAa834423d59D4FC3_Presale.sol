/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Presale is Ownable {

    using Address for address;

    struct TokenDetails {
        uint256 depositLimit;
        uint256 price;
    }

    mapping (address => TokenDetails) public tokenDetails;
    mapping (address => uint256) public tokenClaimable;

    mapping (address => bool) public isValidToken;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isBlacklisted;
    mapping (address => mapping (address => uint256)) public userTokenDepositAmount; 
    mapping (address => uint256) public userEthDepositAmount;

    address[] public depositers;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    uint256 public ethDepositLimit;
    uint256 public ethDepositPrice;
    
    bool public isPresaleActive = false;
    bool public isPresalePublic = true;

    bool lock_= false;

    modifier Lock {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    event SetEthDepositPrice (uint256 _price);
    event SetPresaleStartTime (uint256 _startTime);
    event SetPresaleEndTime (uint256 _endTime);
    event SetEthDepositLimit (uint256 _limit);

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }


    // deposit token using this function
    function depositToken (address _token, uint256 _amount) public Lock {
        require(isPresaleActive, "Presale is not active");
        require(isPresalePublic || isWhitelisted[msg.sender], "You are not whitelisted");
        require(!isBlacklisted[msg.sender], "You are blacklisted");
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale is not active");
        
        require(isValidToken[_token], "Invalid token");
        safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        require(userTokenDepositAmount[msg.sender][_token] + _amount <= tokenDetails[_token].depositLimit, "Deposit limit exceeded");

        if (tokenClaimable[msg.sender] == 0) depositers.push(msg.sender);

        userTokenDepositAmount[msg.sender][_token] += _amount;
        tokenClaimable[msg.sender] += ((_amount) * (tokenDetails[_token].price)) / (10 ** (IERC20(_token).decimals()));
        
    }

    // deposit eth using this function
    function depositEth () public payable Lock {
        require(isPresaleActive, "Presale is not active");
        require(isPresalePublic || isWhitelisted[msg.sender], "You are not whitelisted");
        require(!isBlacklisted[msg.sender], "You are blacklisted");
        require(block.timestamp >= presaleStartTime && block.timestamp <= presaleEndTime, "Presale is not active");
        
        require(msg.value > 0, "Invalid amount");
        require(userEthDepositAmount[msg.sender] + msg.value <= ethDepositLimit, "Deposit limit exceeded");

        if (tokenClaimable[msg.sender] == 0) depositers.push(msg.sender);
        userEthDepositAmount[msg.sender] += msg.value;
        tokenClaimable[msg.sender] += (msg.value * ethDepositPrice) / (10 ** 18);

        (bool success, ) = payable(address(this)).call{value: msg.value}("");
        success;
    }

    // read only functions

    // get all depositers and their claimable amount
    function getDepositors () public view returns (address[] memory, uint256[] memory) {
        address[] memory _depositers = new address[](depositers.length);
        uint256[] memory _claimable = new uint256[](depositers.length);

        for (uint256 i = 0; i < depositers.length; i++) {
            _depositers[i] = depositers[i];
            _claimable[i] = tokenClaimable[depositers[i]];
        }

        return (_depositers, _claimable);
    }

    // Only owner functions here

    // set presale start time
    function setPresaleStartTime (uint256 _startTime) public onlyOwner {
        presaleStartTime = _startTime;
        emit SetPresaleStartTime(_startTime);
    }

    // set presale end time
    function setPresaleEndTime (uint256 _endTime) public onlyOwner {
        presaleEndTime = _endTime;
        emit SetPresaleEndTime(_endTime);
    }

    // set presale status
    function setPresaleStatus (bool _status) public onlyOwner {
        isPresaleActive = _status;
    }

    // set presale public
    function setPresalePublic (bool _status) public onlyOwner {
        isPresalePublic = _status;
    }

    // set token details
    function setTokenDetails (address _token, uint256 _depositLimit, uint256 _price) public onlyOwner {
        tokenDetails[_token] = TokenDetails(_depositLimit, _price);
        isValidToken[_token] = true;
    }

    // whitelist user
    function whitelistUser (address _user) public onlyOwner {
        isWhitelisted[_user] = true;
    }

    // blacklist user
    function blacklistUser (address _user, bool _flag) public onlyOwner {
        isBlacklisted[_user] = _flag;
    }

    // whitelist users
    function whitelistUsers (address[] memory _users, bool _flag) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = _flag;
        }
    }

    // blacklist users
    function blacklistUsers (address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = true;
        }
    }

    // set eth deposit limit
    function setEthDepositLimit (uint256 _limit) public onlyOwner {
        ethDepositLimit = _limit;
        emit SetEthDepositLimit(_limit);
    }

    // set eth deposit price
    function setEthDepositPrice (uint256 _price) public onlyOwner {
        ethDepositPrice = _price;
        emit SetEthDepositPrice(_price);
    }

    // this function is to withdraw BNB
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }

    // this function is to withdraw tokens
    function withdrawBEP20 (address _tokenAddress) external onlyOwner returns (bool) {
        IERC20 token = IERC20 (_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(msg.sender, balance);
        return success;
    }

}
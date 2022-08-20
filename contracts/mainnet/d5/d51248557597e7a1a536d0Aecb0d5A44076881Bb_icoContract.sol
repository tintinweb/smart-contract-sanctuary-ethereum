/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
// Developed by: Lazarus.ETH for ClearID
////////////////////////////
///////////////////////////
//░█████╗░██╗░░░░░███████╗░█████╗░██████╗░██╗██████╗░
//██╔══██╗██║░░░░░██╔════╝██╔══██╗██╔══██╗██║██╔══██╗
//██║░░╚═╝██║░░░░░█████╗░░███████║██████╔╝██║██║░░██║
//██║░░██╗██║░░░░░██╔══╝░░██╔══██║██╔══██╗██║██║░░██║
//╚█████╔╝███████╗███████╗██║░░██║██║░░██║██║██████╔╝
//░╚════╝░╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═════╝░
////////////////////////////
////////////////////////////

pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract icoContract is ReEntrancyGuard{

    uint256 public RATE = 700000000; // Number of tokens per Ether
    uint256 public minBuy = 199999000; // minimum buy amount
    uint256 public maxBuy = 750000000; // maximum buy amount

    uint256 public START = 1659209651;
    
    uint256 public END = 1660073651; 
  
    uint256 public initialTokens = 35000000000; // Initial number of tokens available;

    mapping(address => uint256) public data;
    mapping(address => uint256) public remainingbuytokens;
    mapping (address => bool) public _isWhitelisted; // allows whitelisted address to buy
    mapping (address => bool) public _hasBought; // checks if address has bought

    address public _presaletokenAddress = 0xbfAD51b4C2a49E0F5D127F836f5dbE3849682b2a;  // address of ico coin
    IERC20 token = IERC20(_presaletokenAddress);
    //declaring owner state variable
    address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor() public {
        owner = msg.sender;
        START = block.timestamp;
        END = block.timestamp + (21 * 86400);
    }

    receive() external payable {}

    function setpresalestart(uint256 start,uint256 end) public {
        require(msg.sender == owner, "only owner may whitelist");
        require(end > start,"Invalid timestamp, End must be greater than start");
        START = start;
        END = end;
    }

    function setpresaletoken(address _token) public {
        require(msg.sender == owner, "only owner may whitelist");
        _presaletokenAddress = _token;
    }

    function setamounts(uint256 rate,uint256 minbuy,uint256 maxbuy,uint256 initialtokens) public {
        require(msg.sender == owner, "only owner may whitelist");
        RATE = rate;
        minBuy = minbuy;
        maxBuy = maxbuy;
        initialTokens = initialtokens;
    }

    function whitelistWallet(address account) public {
        require(msg.sender == owner, "only owner may whitelist");
        if(_isWhitelisted[account] == true) return;
        _isWhitelisted[account] = true;
    }

    function whitelistMultipleWallets(address[] calldata addresses) public {
        require(msg.sender == owner, "only owner may whitelist");
        for (uint256 i; i < addresses.length; ++i) {
            _isWhitelisted[addresses[i]] = true;
        }
    }

    function BlacklistWallet(address account) external {
        require(msg.sender == owner, "only owner may blacklist/unblacklist");
         if(_isWhitelisted[account] == false) return;
        _isWhitelisted[account] = false;
    }

    function buyTokens() external payable {
    if(_hasBought[msg.sender] == false)
    {
        remainingbuytokens[msg.sender] = maxBuy;
    }
    
    require(msg.value > 0, "ETH sent must be more than 0");
    require(block.timestamp > START, "Presale not started yet!");
    require(block.timestamp < END, "Presale Ended!");
    require(initialTokens > 0, "Presale Sold Out!");
    require(_isWhitelisted[msg.sender] == true, "Caller must be whitelisted for buying");

    
    uint256 weiAmount = msg.value; // Calculate tokens to sell
    uint256 tokens = (weiAmount) * (RATE);
    tokens = tokens / (10 ** 18);
    
    require(tokens <= maxBuy,"Max buy exceeded");
    require(tokens >= minBuy,"Minimum Amount not met for buy");

    require(remainingbuytokens[msg.sender] > tokens,"Remaining Buy Limit not enough to buy this amount of Tokens.");
    
    remainingbuytokens[msg.sender] = remainingbuytokens[msg.sender] - tokens;
    
    initialTokens = initialTokens - tokens;
    
    _hasBought[msg.sender] = true;
    uint256 tokensTosend = tokens * (10 ** 9);
    data[msg.sender] = tokens;
    token.transfer(msg.sender, tokensTosend); // Send tokens to buyer
    
  }

    function ethbalance() external view returns (uint256){
        require(msg.sender == owner, "Only Owner may call!");
        return address(this).balance;
    }

    function erc20balance() external view returns (uint256){
        uint256 balance = token.balanceOf(address(this)) / 1000000000 ;
        return balance;
    }

    function recovertokenBalance()  external {
        require(msg.sender == owner, "Only Owner may call!");
        token.transfer(owner,token.balanceOf(address(this)));
    }

    function recoverETH() noReentrant external
    {
        require(msg.sender == owner, "Only Owner may call!");
        address payable recipient = payable(msg.sender);
        if(address(this).balance > 0)
            recipient.transfer(address(this).balance);
    }

}
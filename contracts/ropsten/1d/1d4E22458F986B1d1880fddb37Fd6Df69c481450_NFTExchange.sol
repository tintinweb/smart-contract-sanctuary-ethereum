// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
     *s
     *  - an externally-owned account
     *  - a contract in constructions
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

library SafeMath {

  /**s
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual;

  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public virtual view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual;
  function approve(address spender, uint256 value) public virtual;

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    function balanceOf(uint256 tokenId) public virtual view returns (uint256);
    function setApprovalForAll(address operator, bool approved) public virtual;
    function isApprovedForAll(address account, address operator) public virtual view returns (bool);

    function mintAndTransfer(address[] memory _addrs, uint256 _tokenId, uint256[] memory _amounts, string memory _uri) public virtual;
}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event Fallback(address indexed sender, uint256 amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        ERC20(token).transferFrom(from, address(this), value);

        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback () external payable {
        emit Fallback(msg.sender, msg.value);
    }


    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

}

contract NFTExchange is Ownable, TokenRecipient{
    using SafeMath for uint256;
    using Address for address;
    string public constant name = "Exchange Contract";
    string public constant version = "1.0";

    string private constant SALE_TYPE_BUY = "BUY";
    string private constant SALE_TYPE_BID = "BID";

    mapping(address => bool) public isAdmin;

    constructor(){
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    /* The token used to pay exchange fees. */
    ERC20 private exchangeToken;
    ERC1155 private exchangeNft;
    address private feeWallet;

    modifier adminOnly() {
        require(msg.sender == owner || isAdmin[msg.sender] == true);
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function addAdmin(address _address) external ownerOnly() {
        isAdmin[_address] = true;
    }

    function removeAdmin(address _address) external ownerOnly() {
        isAdmin[_address] = false;
    }

    function setFeeWallet(address _address) external ownerOnly() {
        feeWallet = _address;
    }

    function withdraw(address _token, uint256 amount) external ownerOnly() {
        require(feeWallet != address(0), "require set fee wallet");
        if(_token == address(0)){
            uint256 value = address(this).balance;
            require(value >= amount, "current balance must be than withdraw amount");
            payable(feeWallet).transfer(amount);
        }else{
            require(_token.isContract(), "invalid token contract");
            exchangeToken = ERC20(_token);
            uint256 value = exchangeToken.balanceOf(address(this));
            require(value >= amount, "current balance must be than withdraw amount");
            exchangeToken.transfer(feeWallet, amount);
        }
        
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function exchange(
        address[3] calldata contracts,
        address[8] calldata addrs,
        uint256[3] calldata uints,
        uint256[3] calldata uintTokens,
        string[] memory strs)
        public
        adminOnly()
    {
        require(strs.length == 2, "invalid string array");
        uint256 feeValue = uints[0];
        uint256 sellValue = uints[1];
        uint256 royaltyValue = uints[2];
        uint256 totalValue =  (feeValue + sellValue + royaltyValue);
        
        address fromFee = addrs[0];
        address fromValue = addrs[2];
        address fromRoyalty = addrs[4];

        if(contracts[1] == address(0)){
            require(keccak256(bytes(strs[0])) == keccak256(bytes("BUY")),"invalid sale type");
            require(address(this).balance >=totalValue, "not enough eth balance");
            if(addrs[1] != address(0)){
                payable(addrs[1]).transfer(feeValue);
            }
            if(addrs[3] != address(0) && addrs[3] == addrs[5]){
                payable(addrs[3]).transfer(sellValue + royaltyValue);
            }else{
                if(addrs[3] != address(0)){
                    payable(addrs[3]).transfer(sellValue);
                }
                if(addrs[5]!= address(0)){
                    payable(addrs[5]).transfer(royaltyValue);
                }
            } 
        }else{
            if(keccak256(bytes(strs[0])) == keccak256(bytes("BUY"))) {
                fromFee = address(this);
                fromValue = address(this);
                fromRoyalty = address(this);

                exchangeToken = ERC20(contracts[1]);
                require(exchangeToken.balanceOf(payable(address(this))) >= totalValue, "not enough token balance");
            }else{
                require(contracts[1] != address(0), "can not bid/offer for currency");
            }

            if(addrs[1] != address(0)){
                transferTokens(contracts[1], fromFee, addrs[1], feeValue);
            }
            if(addrs[3] != address(0) && addrs[3] == addrs[5]){
                transferTokens(contracts[1], fromValue, addrs[3], sellValue + royaltyValue);
            }else{
                if(addrs[3] != address(0)){
                    transferTokens(contracts[1], fromValue, addrs[3], sellValue);
                }
                if(addrs[5]!= address(0)){
                    transferTokens(contracts[1], fromRoyalty, addrs[5], royaltyValue);
                }
            } 
        }
            
        if(contracts[2] != address(0)){
            address[] memory addNft = new address[](2);
            addNft[0] = addrs[6];
            addNft[1] = addrs[7];

            uint256[] memory intNft  = new uint256[](2);
            intNft[0] = uintTokens[1];
            intNft[1] = uintTokens[2];

            if(uintTokens[1] > 0 || uintTokens[2] > 0) {
                exchangeNft = ERC1155(contracts[2]);
                exchangeNft.mintAndTransfer(addNft, uintTokens[0],  intNft, strs[1]);
            }
        }
    }


    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
        internal
    {
        if (amount > 0) {
            exchangeToken = ERC20(token);
            if(from == address(this)){
                exchangeToken.transfer(to, amount);
            }else{
                exchangeToken.transferFrom(from, to, amount);
            }
        }
    }
}
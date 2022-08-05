/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity 0.8.4;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.8.4;


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


pragma solidity 0.8.4;



/*
    @title Proxyable a minimal proxy contract based on the EIP-1167 .
    @notice Using this contract is only necessary if you need to create large quantities of a contract.
        The use of proxies can significantly reduce the cost of contract creation at the expense of added complexity
        and as such should only be used when absolutely necessary. you must ensure that the memory of the created proxy
        aligns with the memory of the proxied contract. Inspect the created proxy during development to ensure it's
        functioning as intended.
    @custom::warning Do not destroy the contract you create a proxy too. Destroying the contract will corrupt every proxied
        contracted created from it.
*/
contract Proxyable {
    bool private proxy;

    /// @notice checks to see if this is a proxy contract
    /// @return proxy returns false if this is a proxy and true if not
    function isProxy() external view returns (bool) {
        return proxy;
    }

    /// @notice A modifier to ensure that a proxy contract doesn't attempt to create a proxy of itself.
    modifier isProxyable() {
        require(!proxy, "Unable to create a proxy from a proxy");
        _;
    }

    /// @notice initialize a proxy setting isProxy_ to true to prevents any further calls to initialize_
    function initialize_() external isProxyable {
        proxy = true;
    }

    /// @notice creates a proxy of the derived contract
    /// @return proxyAddress the address of the newly created proxy
    function createProxy() external isProxyable returns (address proxyAddress) {
        // the address of this contract because only a non-proxy contract can call this
        bytes20 deployedAddress = bytes20(address(this));
        assembly {
        // load the free memory pointer
            let fmp := mload(0x40)
        // first 20 bytes of built in proxy bytecode
            mstore(fmp, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
        // store 20 bytes from the target address at the 20th bit (inclusive)
            mstore(add(fmp, 0x14), deployedAddress)
        // store the remaining bytes
            mstore(add(fmp, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        // create a new contract using the proxy memory and return the new address
            proxyAddress := create(0, fmp, 0x37)
        }
        // intiialize the proxy above to set its isProxy_ flag to true
        Proxyable(proxyAddress).initialize_();
    }
}

interface IEclipse {
    function decay() external;
    function bind(address token) external;
}

/** 
 * 
 * Eclipse Contract Generator
 * Generates Proxy Eclipse Contracts For Specified Token Projects
 * Costs A Specified Amount To Have Eclipse Created and Swapper Unlocked
 * Developed by Markymark (DeFi Mark)
 * 
 */ 
contract EclipseGenerator {
    
    using Address for address;
    using SafeMath for uint256;

    // useless contract
    address public immutable useless;
    // parent contract
    address private _parentProxy;
    
    // eclipse data
    struct EclipseLib {
        bool isVerified;
        address tokenRepresentative;
    }
    
    // eclipse => isVerified, tokenRepresentative
    mapping ( address => EclipseLib ) public eclipseContracts;
    
    // Token => Eclipse
    mapping ( address => address ) public tokenToEclipse;
    
    // list of Eclipses
    address[] public eclipseContractList;
    
    // decay tracker
    uint256 public decayIndex;

    // Database Contracts
    address public feeCollector;
    uint256 private _decayPeriod;
    uint256 private _decayFee;
    uint256 private _uselessMinimumToDecayFullBalance;
    uint256 public creationCost;

    struct ListedToken {
        bool isListed;
        uint256 buyFee;
        uint256 sellFee;
        uint256 expectedGas;
        uint256 listedIndex;
    }

    mapping (address => ListedToken) public listedTokens;
    address[] public listed;

    mapping (address => bool) _isMaster;
    modifier onlyMaster(){require(_isMaster[msg.sender], 'Only Master'); _;}
    
    // initialize
    constructor(address uselessToken, uint256 decayPeriod) {
        useless = uselessToken;
        _isMaster[msg.sender] = true;
        _decayPeriod = decayPeriod;
        _decayFee = 10;
        _uselessMinimumToDecayFullBalance = 1000 * 10**18; // 1000 useless
    }

    //////////////////////////////////////////
    ///////    MASTER FUNCTIONS    ///////////
    //////////////////////////////////////////
    
    
    function decayByToken(address _token) external onlyMaster {
        _decay(tokenToEclipse[_token]);
    }
    
    function decayByEclipse(address _Eclipse) external onlyMaster {
        _decay(_Eclipse);
    }
    
    function deleteEclipse(address eclipse) external onlyMaster {
        require(eclipseContracts[eclipse].isVerified, 'Not Eclipse Contract');
        _deleteEclipse(eclipseContracts[eclipse].tokenRepresentative);
    }
    
    function deleteEclipseByToken(address token) external onlyMaster {
        require(eclipseContracts[tokenToEclipse[token]].isVerified, 'Not Eclipse Contract');
        _deleteEclipse(token);
    }
    
    function pullRevenue() external onlyMaster {
        _withdraw();
    }
    
    function withdrawTokens(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, 'Insufficient Balance');
        IERC20(token).transfer(msg.sender, bal);
    }

    function setDecayPeriod(uint256 newPeriod) external onlyMaster {
        _decayPeriod = newPeriod;
    }

    function setFeeCollector(address newCollector) external onlyMaster {
        feeCollector = newCollector;
    }

    function setDecayFee(uint256 newFee) external onlyMaster {
        require(
            newFee <= 30,
            'Fee Too High'
        );
        _decayFee = newFee;
    }
    
    function lockProxy(address proxy) external onlyMaster {
        _parentProxy = proxy;
    }

    function setUselessMinimumToDecayFullBalance(uint minToDecay) external onlyMaster {
        _uselessMinimumToDecayFullBalance = minToDecay;
    }

    function setMasterPriviledge(address user, bool userIsMaster) external onlyMaster {
        _isMaster[user] = userIsMaster;
    }

    function setEclipseCreationCost(uint256 newCost) external onlyMaster {
        creationCost = newCost;
    }
    
    function setFeesForToken(address token, uint256 buyFee, uint256 sellFee) external onlyMaster {
        listedTokens[token].buyFee = buyFee;
        listedTokens[token].sellFee = sellFee;
    }

    function setExpectedGas(address token, uint256 expectedGas) external onlyMaster {
        listedTokens[token].expectedGas = expectedGas;
    }

    function delistTokenAndEclipse(address token) external onlyMaster {
        delistToken(token);
        _deleteEclipse(token);
    }

    function listToken(address token) external onlyMaster {
        _listToken(token, 0, 0, 0);
    }

    function listTokenWithFees(address token, uint256 buyFee, uint256 sellFee, uint256 expectedGas) external onlyMaster {
        _listToken(token, buyFee, sellFee, expectedGas);
    }
    
    function delistToken(address token) public onlyMaster {
        require(
            listedTokens[token].isListed,
            'Not Listed'
        );
        listed[listedTokens[token].listedIndex] = listed[listed.length-1];
        listedTokens[listed[listed.length-1]].listedIndex = listedTokens[token].listedIndex;
        listed.pop();
        delete listedTokens[token];
    }

    function _listToken(address token, uint256 buyFee, uint256 sellFee, uint256 expectedGas) private {
        require(
            !listedTokens[token].isListed,
            'Already Listed'
        );
        listedTokens[token].isListed = true;
        listedTokens[token].buyFee = buyFee;
        listedTokens[token].sellFee = sellFee;
        listedTokens[token].expectedGas = expectedGas;
        listedTokens[token].listedIndex = listed.length;
        listed.push(token);
    }

    function getFeesForToken(address token) external view returns (uint, uint) {
        return (listedTokens[token].buyFee, listedTokens[token].sellFee);
    }
    
    function isListed(address token) external view returns (bool) {
        return listedTokens[token].isListed;
    }

    function getFeeCollector() external view returns(address) {
        return feeCollector;
    }

    function isMaster(address user) external view returns(bool) {
        return _isMaster[user];
    }
    
    function getDecayPeriod() public view returns (uint256) {
        return _decayPeriod;
    }
    
    function getDecayFee() public view returns (uint256) {
        return _decayFee;
    }
    
    function getUselessMinimumToDecayFullBalance() public view returns (uint256) {
        return _uselessMinimumToDecayFullBalance;
    }
    
    function getListedTokens() public view returns (address[] memory) {
        return listed;
    }
    
    
    //////////////////////////////////////////
    ///////    PUBLIC FUNCTIONS    ///////////
    //////////////////////////////////////////
    
    
    function createEclipse(address _tokenToList) external payable {
        require(tx.origin == msg.sender, 'No Proxies Allowed');
        require(msg.value >= creationCost || _isMaster[msg.sender], 'Cost Not Met');
        require(tokenToEclipse[_tokenToList] == address(0), 'Eclipse Already Generated');
        // create proxy
        address hill = Proxyable(payable(_parentProxy)).createProxy();
        // initialize proxy
        IEclipse(payable(hill)).bind(_tokenToList);
        // add to database
        eclipseContracts[address(hill)].isVerified = true;
        eclipseContracts[address(hill)].tokenRepresentative = _tokenToList;
        tokenToEclipse[_tokenToList] = address(hill);
        eclipseContractList.push(address(hill));
        _withdraw();
        emit EclipseCreated(address(hill), _tokenToList);
    }
    
    function iterateDecay(uint256 iterations) external {
        require(iterations <= eclipseContractList.length, 'Too Many Iterations');
        for (uint i = 0; i < iterations; i++) {
            if (decayIndex >= eclipseContractList.length) {
                decayIndex = 0;
            }
            _decay(eclipseContractList[decayIndex]);
            decayIndex++;
        }
    }
    
    function decayAll() external {
        for (uint i = 0; i < eclipseContractList.length; i++) {      
            _decay(eclipseContractList[i]);
        }
    }
    
    //////////////////////////////////////////
    ///////   INTERNAL FUNCTIONS   ///////////
    //////////////////////////////////////////
    
    
    function _decay(address eclipse) internal {
        IEclipse(payable(eclipse)).decay();
    }
    
    function _deleteEclipse(address token) internal {
        uint index = eclipseContractList.length;
        for (uint i = 0; i < eclipseContractList.length; i++) {
            if (tokenToEclipse[token] == eclipseContractList[i]) {
                index = i;
                break;
            }
        }
        require(index < eclipseContractList.length, 'Eclipse Not Found');
        eclipseContractList[index] = eclipseContractList[eclipseContractList.length - 1];
        eclipseContractList.pop();
        delete eclipseContracts[tokenToEclipse[token]];
        delete tokenToEclipse[token];
    }
    
    function _withdraw() internal {
        if (address(this).balance > 0) {
            (bool successful,) = payable(feeCollector).call{value: address(this).balance}("");
            require(successful, 'BNB Transfer Failed');
        }
    }
    
    //////////////////////////////////////////
    ///////     READ FUNCTIONS     ///////////
    //////////////////////////////////////////
    
    function kingOfTheHill() external view returns (address) {
        uint256 max = 0;
        address king;
        for (uint i = 0; i < eclipseContractList.length; i++) {
            uint256 amount = IERC20(useless).balanceOf(eclipseContractList[i]);
            if (amount > max) {
                max = amount;
                king = eclipseContractList[i];
            }
        }
        return king == address(0) ? king : eclipseContracts[king].tokenRepresentative;
    }
    
    function getUselessInEclipse(address _token) external view returns(uint256) {
        if (tokenToEclipse[_token] == address(0)) return 0;
        return IERC20(useless).balanceOf(tokenToEclipse[_token]);
    }
    
    function getEclipseForToken(address _token) external view returns(address) {
        return tokenToEclipse[_token];
    }
    
    function getTokenForEclipse(address _eclipse) external view returns(address) {
        return eclipseContracts[_eclipse].tokenRepresentative;
    }
    
    function isEclipseContractVerified(address _contract) external view returns(bool) {
        return eclipseContracts[_contract].isVerified;
    }
    
    function isTokenListed(address token) external view returns(bool) {
        return tokenToEclipse[token] != address(0);
    }
    
    function getEclipseContractList() external view returns (address[] memory) {
        return eclipseContractList;
    }
    
    function getEclipseContractListLength() external view returns (uint256) {
        return eclipseContractList.length;
    }
    
    receive() external payable {}
    
    //////////////////////////////////////////
    ///////         EVENTS         ///////////
    //////////////////////////////////////////
    
    
    event EclipseCreated(address Eclipse, address tokenListed);
}

pragma solidity 0.8.4;


/** 
 *
 * Useless King Of The Hill Contract
 * Tracks Useless In Contract To Determine Listing on the Useless App
 * Developed by Markymark (DeFi Mark)
 * 
 */

contract EclipseData {    
    address _eclipseToken;
    EclipseGenerator _fetcher;
    uint256 lastDecay;
}


contract Eclipse is EclipseData, Proxyable {
    
    using SafeMath for uint256; 
        
    function bind(address eclipseToken) external {
        require(_eclipseToken == address(0), 'Proxy Already Bound');
        _eclipseToken = eclipseToken;
        _fetcher = EclipseGenerator(payable(msg.sender));
        lastDecay = block.number;
    }
    
    //////////////////////////////////////////
    ///////    MASTER FUNCTIONS    ///////////
    //////////////////////////////////////////
    
    function decay() external {
        address useless = _fetcher.useless();
        uint256 bal = IERC20(useless).balanceOf(address(this));
        if (bal == 0) { return; }

        if (lastDecay + _fetcher.getDecayPeriod() > block.number) { return; }
        lastDecay = block.number;

        uint256 minimum = _fetcher.getUselessMinimumToDecayFullBalance();
        uint256 takeBal = bal <= minimum ? bal : bal * _fetcher.getDecayFee() / 100;
        if (takeBal > 0) {
            bool success = IERC20(useless).transfer(_fetcher.feeCollector(), takeBal);
            require(success, 'Failure on Useless Transfer To Furnace');
        }
        emit Decay(takeBal);
    }
    
    //////////////////////////////////////////
    ///////     READ FUNCTIONS     ///////////
    //////////////////////////////////////////
    
    function getUselessInContract() external view returns (uint256) {
        return IERC20(_fetcher.useless()).balanceOf(address(this));
    }
    
    function getTokenRepresentative() external view returns (address) {
        return _eclipseToken;
    }
    
    // EVENTS
    event Decay(uint256 numUseless);
    
}
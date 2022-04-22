/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/test.sol


pragma solidity >=0.8.0;


contract Uchu is Initializable {
    event Log(address from, string operation, uint16 name, uint256 value);
    address payable public owner;

    /**
    * asset:ETH = 10, WETH = 11, USDT = 20, USDC = 21, WBTC = 30
    * the frontend need decode the number to string name for display.
    * product_id start from 1.
    */
    struct Product {
        uint8 product_id;
        uint8 asset;
        string product_name;
        uint balance;
        uint debt;
        uint lending_share;
        uint borrowing_share;
        uint lastest_change_time;
        address creator;
    }

    // position_id start from 1.
    struct Position {
        uint position_id;
        uint share;
    }

    struct Loan {
        uint32 loan_id;
        uint share;
    }

    uint8 private proCount;
    uint private loanCount;
    uint private positionCount;
    Product[] private product_list;
    mapping (address => mapping(uint8 => Loan)) private loan_map;
    mapping (address => mapping(uint8 => Position)) private position_map;

    function initialize() public payable initializer {
        owner = payable(msg.sender);
    }

    function createProduct(uint8 asset, string memory name) public returns (bool) {
        for(uint8 i=0; i<proCount; i++) {
            if (asset == product_list[i].asset)
                return false;
        }
        product_list.push(Product(++proCount, asset, name, 0, 0, 0, 0, block.timestamp, msg.sender));
        return true;
    }

    function getProducts() public view returns (Product[] memory) {
        return product_list;
    }

    function getProduct(uint8 productId) public view returns (Product memory) {
        for (uint8 i=0; i<proCount; i++) {
            if (product_list[i].product_id == productId) {
                return product_list[i];
            }
        }
    }

    /**
    * start: the start millisecond
    * end : the end millisecond
    * return: natural days
    **/
    function getDays(uint start, uint end) private pure returns (uint) {
        if (start > end) {
            return 0;
        }
        return end / 1 days - start / 1 days;
    }

    function getPositions(address user) public view returns (Position[] memory) {
        Position[] memory pos = new Position[](positionCount);
        for(uint8 i=0; i<positionCount; i++) {
            pos[i]= position_map[user][i + 1];
        }
        return pos;
    }

    function getPosition(address user, uint8 productId) public view returns (Position memory) {
        return position_map[user][productId];
    }

    function getLoans(address user) public view returns (Loan[] memory) {
        Loan[] memory loan = new Loan[](loanCount);
        for(uint8 i=0; i<loanCount; i++) {
            loan[i]= loan_map[user][i];
        }
        return loan;
    }

    /**
    * deposit by current productId
    **/
    function deposit(address user, uint8 productId) public payable returns (bool) {
        if (proCount > 0) {
            updateProduct(productId, msg.value);
            updatePosition(user, productId, msg.value);
            return true;
        } else {
            require(proCount > 0, "No product!");
            return false;
        }
    }

    function withdraw(address user, uint8 productId, uint amount) public returns (bool) {
        if(product_list[productId].balance >= amount) {
            payable(user).transfer(amount);
            return true;
        } else {
            require(product_list[productId].balance >= amount, "Allowance is not enough!");
            return false;
        }
    }

    function updateProduct(uint8 productId, uint amount) private {
        for (uint8 i=0; i<proCount; i++) {
            if (product_list[i].product_id == productId) {
                if (product_list[i].debt == 0) {
                    product_list[i].lending_share = amount;
                    product_list[i].balance = amount;
                } else {

                }
                product_list[i].lastest_change_time = block.timestamp;
            }
        }
    }

    function updatePosition(address user, uint8 productId, uint amount) private {
        Product memory product = getProduct(productId);
        Position memory pos = position_map[user][productId];
        if (pos.position_id == 0) {
            position_map[user][productId] = Position(++positionCount, amount);
        } else {
            if (product.debt == 0) {
                position_map[user][productId].share += amount;
            } else {
                
            }
        }
    }

    /**
    * return a position to update it.
    **/
    function lenderShare(address user, uint8 productId, uint amount) private returns (Position memory) {
        Product memory product = getProduct(productId);
        Position memory pos = position_map[user][productId];
        return Position(++positionCount, amount);
    }

    function setProductBalance(uint8 productId, uint amount) private {

    }

    function setProductDebt(uint8 productId, uint amount) private returns (uint) {

    }

    function setProductLendShare(uint8 productId, uint amount) private returns (uint) {

    }

    function setProductBorrowShare(uint8 productId, uint amount) private returns (uint) {

    }

    function productPrice() private pure returns (uint) {
        
    }

    function lenderBalance(Product memory product) private returns (uint) {

    }

    function borrowerShare(Product memory product) private returns (Loan memory) {

    }

    function borrowerDebt(Product memory product) private returns (uint) {

    }
    
    function borrow(address user, uint amount, uint8 productId) public returns (bool) {
        if (product_list[productId].debt >= amount) {
            Product memory product = getProduct(productId);
            product.lastest_change_time = block.timestamp;
            loan_map[user][productId] = borrowerShare(product);
            payable(user).transfer(amount);
            return true;
        } else {
            require(product_list[productId].debt >= amount, "Allowance is not enough!");
            return false;
        }
    }

    function repay(address user, uint8 productId) public payable returns (bool) {
            return true;
    }

}
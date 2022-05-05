/**
 *Submitted for verification at Etherscan.io on 2022-05-05
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

// File: uchu/uchu8.sol


pragma solidity >=0.8.0;


contract Uchu is Initializable {
    event Log(address from, string operation, uint16 name, uint256 value);
    address payable public owner;

    /**
    * asset:ETH = 10, WETH = 11, USDT = 20, USDC = 21, WBTC = 30
    * the frontend need decode the number to string name for display.
    * product_id start from 0.
    */
    struct Product {
        uint8 product_id;
        uint8 asset;
        uint8 borrow_rate_factor;
        string product_name;
        uint balance;
        uint debt;
        uint lending_share;
        uint borrowing_share;
        uint lastest_change_time;
        address creator;
    }

    struct Position {
        uint8 product_id;
        uint share;
    }

    struct Loan {
        uint8 product_id;
        uint share;
    }

    uint8 private proCount;
    Product[] private product_list;
    mapping (address => Loan[]) private loan_map;
    mapping (address => Position[]) private position_map;

    function initialize() public payable initializer {
        owner = payable(msg.sender);
    }

    function createProduct(uint8 asset, string memory name, uint8 rate) public returns (bool) {
        for(uint8 i=0; i<proCount; i++) {
            if (asset == product_list[i].asset)
                return false;
        }
        product_list.push(Product(proCount++, asset, rate, name, 0, 0, 0, 0, block.timestamp, msg.sender));
        return true;
    }

    function getProducts() public view returns (Product[] memory) {
        return product_list;
    }

    function getProduct(uint8 productId) public view returns (Product memory) {
        return product_list[productId];
    }

    /**
    * start: the start millisecond
    * end : the end millisecond
    * return: natural days
    **/
    function getDays(uint start, uint end) private pure returns (uint16) {
        if (start > end) {
            return 0;
        }
        return uint16(end / 5 minutes - start / 5 minutes);
    }

    function getPositions(address user) public view returns (Position[] memory) {
        return position_map[user];
    }

    function getLoans(address user) public view returns (Loan[] memory) {
        return loan_map[user];
    }

    function isProduct(uint8 productId) private returns (bool) {
        if (product_list[productId].asset != 0) {
            return true;
        }
        return false;
    }

    /**
    * Deposit by current productId
    **/
    function deposit(address user, uint8 productId) public payable returns (bool) {
        bool isIn = isProduct(productId);
        if (isIn) {
            updateProduct(productId, msg.value, 0, 0, 0);
            return true;
        } else {
            require(isIn, "No this product!");
            return false;
        }
    }

    function withdraw(address user, uint8 productId, uint amount) public returns (bool) {
        if(product_list[productId].balance >= amount && product_list[productId].debt != 0) {
            updateProduct(productId, 0, amount, 0, 0);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }
    
    function borrow(address user, uint amount, uint8 productId) public returns (bool) {
        if (product_list[productId].balance >= amount) {
            updateProduct(productId, 0, 0, amount, 0);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    function repay(address user, uint8 productId) public payable returns (bool) {
        bool isIn = isProduct(productId);
        if (isIn) {
            updateProduct(productId, 0, 0, 0, msg.value);
            return true;
        } else {
            return false;
        }
    }

    /**
    * Go through the products to update by productId.
    **/
    function updateProduct(uint8 productId, uint deposit, uint withdraw, uint borrow, uint repay) private {
        if (product_list[productId].debt == 0) {
            if (deposit != 0) {
                product_list[productId].lending_share += deposit;
                product_list[productId].balance += deposit;
            } else if (borrow != 0) {
                product_list[productId].debt = setProductDebt(productId, 0, 0, false);
                product_list[productId].debt = setProductDebt(productId, borrow, 0, true);
                product_list[productId].borrowing_share += borrow;
                product_list[productId].balance -= borrow;
            }
        } else {
            product_list[productId].debt = setProductDebt(productId, 0, 0, false);
            if (deposit != 0) {
                //update postion by last debt
                updatePosition(msg.sender, productId, deposit, 0);
                product_list[productId].lending_share = setProductLendingShare(productId, deposit, 0);
                product_list[productId].debt = setProductDebt(productId, 0, 0, true);
                product_list[productId].balance += deposit;
            } else if (withdraw != 0) {
                //update postion by last debt
                updatePosition(msg.sender, productId, 0, withdraw);
                product_list[productId].lending_share = setProductLendingShare(productId, 0, withdraw);
                product_list[productId].debt = setProductDebt(productId, 0, 0, true);
                product_list[productId].balance -= withdraw;
            } else if (borrow != 0) {
                //update loan by last debt
                updateLoan(msg.sender, productId, borrow, 0);
                product_list[productId].borrowing_share = setProductBorrowingShare(productId, borrow, 0);
                product_list[productId].debt = setProductDebt(productId, borrow, 0, true);
                product_list[productId].balance -= borrow;
            } else if (repay != 0) {
                //update loan by last debt
                updateLoan(msg.sender, productId, 0, repay);
                product_list[productId].borrowing_share = setProductBorrowingShare(productId, 0, repay);
                product_list[productId].debt = setProductDebt(productId, 0, repay, true);
                product_list[productId].balance += repay;
            }
        }
        product_list[productId].lastest_change_time = block.timestamp;
    }

    /**
    * Go through the positions to update by productId.
    **/
    function updatePosition(address user, uint8 productId, uint deposit, uint withdraw) private {
        uint size = position_map[user].length;
        for (uint i=0; i<size; i++) {
            //in the array
            if (position_map[user][i].product_id == productId) {
                lenderShare(user, productId, i, deposit, withdraw, true);
                return;
            }
        }
        //not in the array
        lenderShare(user, productId, size, deposit, withdraw, false);
    }

    /**
    * Postions upgrade strategy by address.
    **/
    function lenderShare(address user, uint8 productId, uint index, uint deposit, uint withdraw, bool isIn) private {
        Product memory product = product_list[productId];
        if (!isIn) {
            position_map[user].push(Position(productId, 0));
        }
        if (product.debt == 0) {
            position_map[user][index].share += deposit;
        } else {
            position_map[user][index].share += (deposit - withdraw) / lendingPrice(productId, deposit, withdraw);
        }
    }

    /**
    * Go through the loans to update by productId.
    **/
    function updateLoan(address user, uint8 productId, uint borrow, uint repay) private {
        uint size = loan_map[user].length;
        for (uint i=0; i<size; i++) {
            if (loan_map[user][i].product_id == productId) {
                borrowerShare(user, productId, i, borrow, repay, true);
                return;
            }
        }
        borrowerShare(user, productId, size, borrow, repay, false);
    }

    /**
    * Loans upgrade strategy by address.
    **/
    function borrowerShare(address user, uint8 productId, uint index, uint borrow, uint repay, bool isIn) private {
        Product memory product = product_list[productId];
        if (!isIn) {
            loan_map[user].push(Loan(productId, 0));
        }
        if (product.debt == 0) {
            loan_map[user][index].share += borrow;
        } else {
            loan_map[user][index].share += (borrow - repay) / borrowingPrice(product);
        }
    }

    /**
    * return lender earning in debt.
    **/
    function lenderEarning(uint8 productId) private returns (uint) {
        Product memory product = product_list[productId];
        uint realDebt = product.debt;
        uint amount = product.balance + product.debt;
        uint numerator = 1000 * amount + product.debt;
        uint denominator = 1000 * amount;
        uint16 pow = getDays(product.lastest_change_time, block.timestamp);
        return realDebt * (numerator ** pow) / (denominator ** pow);
    }

    /**
    * return lending share price.
    **/
    function lendingPrice(uint8 productId, uint deposit, uint withdraw) private returns (uint) {
        Product memory product = product_list[productId];
        uint totalAmount = product.balance + lenderEarning(productId);
        return totalAmount / setProductLendingShare(productId, deposit, withdraw);
    }

    /**
    * return borrowing share price.
    **/
    function borrowingPrice(Product memory product) private pure returns (uint) {
        if (product.borrowing_share == 0) {
            return 0;
        }
        return product.debt / product.borrowing_share;
    }

    /**
    * return the total lending share.
    **/
    function setProductLendingShare(uint8 productId, uint deposit, uint withdraw) private returns (uint) {
        Product memory product = product_list[productId];
        uint totalAmount = product.balance + lenderEarning(productId);
        return product.lending_share * (totalAmount + deposit - withdraw) / totalAmount;
    }
    
    /**
    * return the total debt.
    **/
    function setProductDebt(uint8 productId, uint borrow, uint repay, bool isChange) private returns (uint) {
        Product memory product = product_list[productId];
        uint realDebt = product.debt + borrow - repay;
        uint amount = product.balance + product.debt;
        uint numerator = 100000 * amount + (product.borrow_rate_factor * amount + 100 * product.debt);
        uint denominator = 100000 * amount;
        if (!isChange) {
            uint16 pow = getDays(product.lastest_change_time, block.timestamp) + 1;
            return realDebt * (numerator ** pow) / (denominator ** pow);
        } else {
            return realDebt * numerator / denominator;
        }
    }

    /**
    * return the total borrowing share.
    **/
    function setProductBorrowingShare(uint8 productId, uint borrow, uint repay) private returns (uint) {
        Product memory product = product_list[productId];
        if (product.borrowing_share == 0) {
            return borrow - repay;
        }
        return product.borrowing_share * (product.debt + borrow - repay) / product.debt;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2022-03-30
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

// File: contracts/uchu.sol


pragma solidity >=0.8.0;


contract Uchu is Initializable {
// contract Uchu {
 
    event Log(address from, string operation, uint8 name, uint256 value);
    address payable public owner;

    /**
    * asset:ETH = 10,USDT = 21,WBTC = 31
    * Product Name is unique and there must not be 2 products that have same names. Product Name = Asset + Number of Day.
    * name:ETH7 = 107,ETH14 = 1014,USDT30 = 2130,USDT90 = 2190,WBTC365 = 31365...
    * the frontend need decode the number to string name for display.
    */
    struct Product {
        uint8 id;
        uint8 yieldNum;
        uint8 totalNum;
        uint8 lockPeriod;
        uint8 asset;
        uint8 name;
        address creator;
        uint256 createTime;
    }

    struct Position {
        uint8 proId;
        uint8 status;
        uint32 lenderId;
        uint32 borrowerId;
        uint256 amount;
        uint256 createTime;
        uint256 closeTime;
    }

    struct Lender {
        uint32 id;
        uint8 proId;
        uint8 posIndex;
        address lender;
    }

    struct Borrower {
        uint32 id;
        uint8 proId;
        uint8 posIndex;
        address borrower;
    }

    /*
    * OPEN: Lender deposited the funds.
    * LOCKTIMEUP_UNREPAID: The position lock time ends but the lender can not withdraw all the funds because the borrower failed to repay the full amount.
    * LOCKTIMEUP_ALL_REPAID: The position lock time ends and the lender can withdraw the funds.
    * CLOSED: Funds are withdrawn by the lender.
    */
    uint8 OPEN = 10;
    uint8 LOCKTIMEUP_UNREPAID = 80;
    uint8 LOCKTIMEUP_ALL_REPAID = 90;
    uint8 CLOSED = 100;

    uint8 private productId;
    uint32 private lenderId;
    uint32 private borrowerId;
    mapping (uint8 => Product) private products;
    mapping (uint32 => Lender) private lenders;
    mapping (uint32 => Borrower) private borrowers;
    mapping (uint8 => uint256) private allowance;
    mapping (address => mapping(uint8 => uint256)) private debts;
    mapping (address => mapping(uint8 => uint256)) private balanceOf;
    mapping (address => mapping(uint8 => Position)) private positions;

    function initialize() public payable initializer {
        owner = payable(msg.sender);
    }

    // constructor() {
    //     owner = payable(msg.sender);
    // }

    function createProduct(uint8 yeildNum, uint8 totalNum, uint8 lockPeriod, uint8 asset, uint8 name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, asset, name, owner, 0);
        createBorrower(owner, productId);
        productId++;
    }

    function createBorrower(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<borrowerId; i++) {
            if(pro.id == borrowers[i].proId) {
                return;
            }
        }
        borrowers[borrowerId] = Borrower(borrowerId + 1, pro.id, 0, user);
        borrowerId++;
    }

   /**
    * get products from borrowers by address.
    */
    function getBorrowerProducts(address user) public view returns (Product[] memory) {
        Product[] memory pro = new Product[](borrowerId);
        for(uint32 i=0;i<borrowerId;i++) {
            if(user == borrowers[i].borrower)
                pro[i]= products[borrowers[i].proId];
        }
        return pro;
    }

    /**
    * return all products
    */
    function getProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](productId);
        for(uint8 i=0;i<productId;i++) {
            pro[i]= products[i];
        }
        return pro;
    }

    function getProduct(uint8 proId) public view returns (Product memory pro) {
        for(uint8 i=0; i<productId; i++) {
            if(proId == products[i].id)
                return products[i];
        }
    }

    /**
    * deposit by current product, proId = index
    **/
    function deposit(uint8 proId) public payable returns (bool) {
        if (productId > 0) {
            Product memory pro = getProduct(proId);
            balanceOf[msg.sender][pro.name] += msg.value;
            allowance[pro.name] += msg.value;
            createLender(msg.sender, proId);
            createPosition(proId, OPEN, msg.sender, msg.value,  block.timestamp, 0);
            emit Log(msg.sender, "deposit", pro.name, msg.value);
            return true;
        } else {
            return false;
        }
    }

    function createLender(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<lenderId; i++) {
            if(pro.id == lenders[i].proId) {
                return;
            }
        }
        lenders[lenderId] = Lender(lenderId + 1, pro.id, 0, user);
        lenderId++;
    }

    /**
    *  insert record by current lender's positionIndex
    **/
    function createPosition(uint8 proId, uint8 status, address user, uint256 amount, uint256 depositTime, uint256 withdrawTime) private {
        Lender memory lender = getCurLender(user);
        positions[msg.sender][lender.posIndex] = Position(proId, status, lender.id, 0, amount, depositTime, withdrawTime);
            for(uint32 i=0; i<lenderId; i++) {
                if(msg.sender == lenders[i].lender) {
                    lenders[i].posIndex++;
                    break;
                }
            }
    }

   /**
    * get products from lenders by address
    */
    function getLenderProducts(address user) public view returns (Product[] memory) {
        Product[] memory pro = new Product[](lenderId);
        for(uint32 i=0;i<lenderId;i++) {
            if(user == lenders[i].lender)
                pro[i]= products[lenders[i].proId];
        }
        return pro;
    }

    function getDeposit(uint8 name) public view returns (uint256) {
        return allowance[name];
    }

    function getDeposit(address user, uint8 name) public view returns (uint256) {
        return balanceOf[user][name];
    }

    /**
    *   return current lender
    **/
    function getCurLender(address user) private view returns (Lender memory lender) {
        for(uint32 i=0; i<lenderId; i++) {
            if(user == lenders[i].lender) {
                lender = lenders[i];
                break;
            }
        }
        return lender;
    }

    /**
    *  caculate user's current product balance with profit
    **/
    function getProductReturn(address user, uint8 proId) public view returns (uint256) {
        uint8 length = getCurLender(user).posIndex;
        Product memory pro = getProduct(proId);
        uint256 result;
        for(uint8 i=0; i<length; i++) {
            if(positions[user][i].proId == proId) {
                uint256 start = block.timestamp;
                uint256 end = positions[user][i].createTime;
                uint256 amount = positions[user][i].amount;
                uint256 pow = calculateTimeGap(start, end, pro.lockPeriod);
                uint256 total = pro.yieldNum + pro.totalNum;
                if (pow > 1) {
                    result += amount / (100 ** pow) * (total ** pow);
                } else {
                    result = amount;
                }
            }
        }
        return result;
    }

    /**
    * start: the time
    * end:  the creat time
    * period: the minimum time unit of day
    **/
    function calculateTimeGap(uint256 start, uint256 end, uint128 period) private pure returns (uint256) {
        uint256 step = start - end;
        uint256 num = 60 * 60 * 24 * period;
        uint256 base = step - (step % num);
        if (base <= num) {
            return 1;
        }
        return base / num;
    }

    function getPositions(address user) public view returns (Position[] memory) {
        uint8 length = getCurLender(user).posIndex;
        Position[] memory history = new Position[](length);
        for(uint8 i=0; i<length; i++) {
            history[i] = positions[user][i];
        }
        return history;
    }

    function withdraw(address user, uint256 amount, uint8 proId) public returns (bool) {
        Product memory pro = getProduct(proId);
        if (balanceOf[user][pro.name] >= amount) {
            allowance[pro.name] -= amount;
            balanceOf[user][pro.name] -= amount;
            createPosition(proId, CLOSED, user, amount, 0, block.timestamp);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    function borrow(address user, uint256 amount, uint8 proId) public returns (bool) {
            Product memory pro = getProduct(proId);
        if (allowance[pro.name] >= amount) {
            allowance[pro.name] -= amount;
            debts[user][pro.name] += amount;
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    function repay(address user, uint8 proId) public payable returns (bool) {
            Product memory pro = getProduct(proId);
        if (debts[user][pro.name] >= msg.value) {
            allowance[pro.name] += msg.value;
            debts[user][pro.name] -= msg.value;
            return true;
        } else {
            return false;
        }
    }
}
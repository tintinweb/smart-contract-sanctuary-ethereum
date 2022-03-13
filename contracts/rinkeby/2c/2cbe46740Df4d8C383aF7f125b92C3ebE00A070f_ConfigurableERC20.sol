/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

//  SPDX-License-Identifier: MIT

/*
   _____             __ _                       _     _      
  / ____|           / _(_)                     | |   | |     v2 -> Matic Compatible
 | |     ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |__ | | ___ 
 | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | '_ \| |/ _ \
 | |___| (_) | | | | | | | (_| | |_| | | | (_| | |_) | |  __/
  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|_.__/|_|\___|
                           __/ |                             
  ______ _____   _____ ___|___/_                             
 |  ____|  __ \ / ____|__ \ / _ \                            
 | |__  | |__) | |       ) | | | |                           
 |  __| |  _  /| |      / /| | | |                           
 | |____| | \ \| |____ / /_| |_| |                           
 |______|_|  \_\\_____|____|\___/ 
 
 By the team that brought you:
  --- > Circuits of Value (http://circuitsofvalue.com)
  --- > Emblem Vault (https://emblem.finance)
  
 Documentation:
  --- > Github (https://github.com/EmblemLabs/ConfigurableERC20)
  
 UI:
  --- > (https://emblemlabs.github.io/ConfigurableERC20/)
*/

pragma solidity 0.8.4;
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./HasRegistration.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract ERC20Detailed is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool initialized;

    function init(string memory _name, string memory _symbol, uint8 _decimals) public {
        require(!initialized, "Already Initialized");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract Configurable is HasRegistration {
    using SafeMath for uint256;

    address private governance;
    bool internal _transferable = true;
    bool internal _burnable = true;
    bool internal _visible = true;
    bool internal _allowPrivateTransactions = false;
    bool internal _locked = false;
    bool internal _forever = false;
    uint256 internal _lockBlock = 0;

    mapping(address => bool) public minters;
    mapping(address => bool) public viewers;
    mapping(address => bool) public depositers;

    function _isGoverner() internal view returns (bool) {
        return _msgSender() == governance;
    }

    function _isViewer() internal view returns (bool) {
        return viewers[_msgSender()];
    }

    function _isMinter() internal view returns (bool) {
        return minters[_msgSender()];
    }
    
    function _isDepositer() internal view returns (bool) {
        return depositers[_msgSender()];
    }


    function transferable() public view returns (bool) {
        return _transferable;
    }

    function burnable() public view returns (bool) {
        return _burnable;
    }

    function visible() public view returns (bool) {
        return _visible;
    }

    function visibleOrAdmin() public view returns (bool) {
        return _visible || _isGoverner();
    }

    function allowPrivateTransactions() public view returns (bool) {
        return _allowPrivateTransactions;
    }

    function blockNumberLocked() public view returns (bool) {
        return _lockBlock != 0 && block.number < _lockBlock;
    }

    function locked() public view returns (bool) {
        return _locked || blockNumberLocked();
    }

    function lockedPermenantly() public view returns (bool) {
        return locked() && _forever;
    }

    function blocksTillUnlock() public view returns (uint256) {
        if (_lockBlock > block.number) {
            return _lockBlock.sub(block.number);
        } else {
            return 0;
        }
    }

    modifier isTransferable() {
        require(_transferable, "Contract does not allow transfering");
        _;
    }

    modifier isBurnable() {
        require(_burnable, "Contract does not allow burning");
        _;
    }

    modifier isVisibleOrCanView() {
        require(
            _visible || _isViewer() || _isGoverner(),
            "Contract is private and you are not Governer or on viewers list"
        );
        _;
    }

    modifier canSendPrivateOrGoverner() {
        require(
            _allowPrivateTransactions || _isGoverner(),
            "Contract cannot send private transactions"
        );
        _;
    }

    modifier onlyOwner() override {
        require(_isGoverner(), "Sender is not Governer");
        _;
    }

    modifier notLocked() {
        require(!locked(), "Contract is locked to governance changes");
        _;
    }

    modifier canMint() {
        require(_isMinter(), "No Minting Privilages");
        _;
    }
    
    modifier canDeposit() {
        require(_isDepositer(), "No Depositing Privilages");
        _;
    }

    function unLock() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        require(locked(), "Contract not locked");
        _locked = false;
    }

    function lockForever() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        _locked = true;
        _forever = true;
    }

    function lockTemporarily() public onlyOwner notLocked {
        _locked = true;
    }

    function lockTemporarilyTillBlock(uint256 blockNumber)
        public
        onlyOwner
        notLocked
    {
        require(
            block.number < blockNumber,
            "Provided Block numbner is in the past"
        );
        _lockBlock = blockNumber;
    }

    function toggleBurnable() public onlyOwner notLocked {
        _burnable = !_burnable;
    }

    function toggleTransferable() public onlyOwner notLocked {
        _transferable = !_transferable;
    }

    function toggleVisibility() public onlyOwner notLocked {
        _visible = !_visible;
    }

    function togglePrivateTransferability() public onlyOwner notLocked {
        _allowPrivateTransactions = !_allowPrivateTransactions;
    }

    function setGovernance(address _governance) public onlyOwner notLocked {
        _setGovernance(_governance);
    }
    
    /* For compatibility with Ownable */
    function transferOwnership(address _governance) public override onlyOwner notLocked {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) internal {
        minters[governance] = false; // Remove old owner from minters list
        viewers[governance] = false; // Remove old owner from viewers list
        depositers[governance] = false; //Remove old owner from depositer list
        minters[_governance] = true; // Add new owner to minters list
        viewers[_governance] = true; // Add new owner to viewers list
        depositers[_governance] = true; //Add new owner from depositer list
        governance = _governance; // Set new owner
    }
}

contract ERC20 is IERC20, Configurable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply()
        public
        override
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        override
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override isTransferable returns (bool) {
        _transferFromPrivate(sender, recipient, amount, visible());
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
    
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
    
    function deposit(address user, bytes calldata depositData)
        external
        canDeposit
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function _transferFromPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable returns (bool) {
        _transferPrivate(sender, recipient, amount, _private);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        isTransferable
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal isTransferable {
        _transferPrivate(sender, recipient, amount, !visible());
    }

    function _transferPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        if (!_private) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        if (visible()) {
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        if (visible()) {
            emit Transfer(account, address(0), amount);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        if (visible()) {
            emit Approval(owner, spender, amount);
        }
    }
}

contract ConfigurableERC20 is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor() {
        init(_msgSender(), name, symbol, decimals);
    }

    function init(address _owner, string memory _name, string memory _symbol, uint8 _decimals) public {
        require(!initialized, "Already Initialized");
        ERC20Detailed.init(_name, _symbol, _decimals);      
        _setGovernance(_owner);
        Configurable._transferable = true;
        Configurable._burnable = true;
        Configurable._visible = true;
        Configurable._allowPrivateTransactions = false;
        Configurable._locked = false;
        Configurable._forever = false;
        Configurable._lockBlock = 0; 
        initialized = true;
    }

    function transfer(
        address to,
        uint256 amount,
        bool _private
    ) public isTransferable canSendPrivateOrGoverner {
        _transferPrivate(_msgSender(), to, amount, _private);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bool _private
    ) public isTransferable canSendPrivateOrGoverner {
        _transferPrivate(from, to, amount, _private);
    }

    function mint(address account, uint256 amount) public canMint notLocked {
        _mint(account, amount);
    }

    function burn(uint256 amount) public isBurnable {
        _burn(_msgSender(), amount);
    }

    function changeContractDetails(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public onlyOwner notLocked {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function addMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = false;
    }

    function addViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = true;
    }

    function removeViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = false;
    }
    
    function addDepositer(address _depositer) public onlyOwner notLocked {
        depositers[_depositer] = true;
    }

    function removeDepositer(address _depositer) public onlyOwner notLocked {
        depositers[_depositer] = false;
    }
}

pragma solidity 0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

pragma solidity 0.8.4;
contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.4;
import "./Context.sol";
import "./Ownable.sol";

interface IRegistrationStorage {
    function upgradeVersion(address _newVersion) external;
}

contract HasRegistration is Context, Ownable {

    // address StorageAddress;
    // bool initialized = false;

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING, 10 BYPASS
    mapping(uint256 => address[]) public registeredOfType;
    
    uint256 public contractCount = 0;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    // constructor(address storageContract) {
    //     StorageAddress = storageContract;
    // }

    // function initialize() public {
    //     require(!initialized, 'already initialized');
    //     IRegistrationStorage _storage = IRegistrationStorage(StorageAddress);
    //     _storage.upgradeVersion(address(this));
    //     initialized = true;
    // }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        contractCount++;
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        require(contractCount > 0, 'No vault contracts to remove');
        delete registeredOfType[registeredContracts[_contract]][index];
        delete registeredContracts[_contract];
        contractCount--;
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }
}

pragma solidity 0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

pragma solidity 0.8.4;
/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() virtual
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    virtual
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}
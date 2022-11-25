/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





abstract contract IDFSRegistry {
 
    function getAddr(bytes4 _id) public view virtual returns (address);

    function addNewContract(
        bytes32 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public virtual;

    function startContractChange(bytes32 _id, address _newContractAddr) public virtual;

    function approveContractChange(bytes32 _id) public virtual;

    function cancelContractChange(bytes32 _id) public virtual;

    function changeWaitPeriod(bytes32 _id, uint256 _newWaitPeriod) public virtual;
}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;
    address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
    address internal constant ADMIN_ADDR = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9; // USED IN ADMIN VAULT CONSTRUCTOR
}





contract AuthHelper is MainnetAuthAddresses {
}





contract AdminVault is AuthHelper {
    address public owner;
    address public admin;

    error SenderNotAdmin();

    constructor() {
        owner = msg.sender;
        admin = ADMIN_ADDR;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        admin = _admin;
    }

}








contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender){
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender){
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}





contract DFSRegistry is AdminAuth {
    error EntryAlreadyExistsError(bytes4);
    error EntryNonExistentError(bytes4);
    error EntryNotInChangeError(bytes4);
    error ChangeNotReadyError(uint256,uint256);
    error EmptyPrevAddrError(bytes4);
    error AlreadyInContractChangeError(bytes4);
    error AlreadyInWaitPeriodChangeError(bytes4);

    event AddNewContract(address,bytes4,address,uint256);
    event RevertToPreviousAddress(address,bytes4,address,address);
    event StartContractChange(address,bytes4,address,address);
    event ApproveContractChange(address,bytes4,address,address);
    event CancelContractChange(address,bytes4,address,address);
    event StartWaitPeriodChange(address,bytes4,uint256);
    event ApproveWaitPeriodChange(address,bytes4,uint256,uint256);
    event CancelWaitPeriodChange(address,bytes4,uint256,uint256);

    struct Entry {
        address contractAddr;
        uint256 waitPeriod;
        uint256 changeStartTime;
        bool inContractChange;
        bool inWaitPeriodChange;
        bool exists;
    }

    mapping(bytes4 => Entry) public entries;
    mapping(bytes4 => address) public previousAddresses;

    mapping(bytes4 => address) public pendingAddresses;
    mapping(bytes4 => uint256) public pendingWaitTimes;

    /// @notice Given an contract id returns the registered address
    /// @dev Id is keccak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes4 _id) public view returns (address) {
        return entries[_id].contractAddr;
    }

    /// @notice Helper function to easily query if id is registered
    /// @param _id Id of contract
    function isRegistered(bytes4 _id) public view returns (bool) {
        return entries[_id].exists;
    }

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    /// @param _waitPeriod Amount of time to wait before a contract address can be changed
    function addNewContract(
        bytes4 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public onlyOwner {
        if (entries[_id].exists){
            revert EntryAlreadyExistsError(_id);
        }

        entries[_id] = Entry({
            contractAddr: _contractAddr,
            waitPeriod: _waitPeriod,
            changeStartTime: 0,
            inContractChange: false,
            inWaitPeriodChange: false,
            exists: true
        });

        emit AddNewContract(msg.sender, _id, _contractAddr, _waitPeriod);
    }

    /// @notice Reverts to the previous address immediately
    /// @dev In case the new version has a fault, a quick way to fallback to the old contract
    /// @param _id Id of contract
    function revertToPreviousAddress(bytes4 _id) public onlyOwner {
        if (!(entries[_id].exists)){
            revert EntryNonExistentError(_id);
        }
        if (previousAddresses[_id] == address(0)){
            revert EmptyPrevAddrError(_id);
        }

        address currentAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = previousAddresses[_id];

        emit RevertToPreviousAddress(msg.sender, _id, currentAddr, previousAddresses[_id]);
    }

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes4 _id, address _newContractAddr) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (entries[_id].inWaitPeriodChange){
            revert AlreadyInWaitPeriodChangeError(_id);
        }

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inContractChange = true;

        pendingAddresses[_id] = _newContractAddr;

        emit StartContractChange(msg.sender, _id, entries[_id].contractAddr, _newContractAddr);
    }

    /// @notice Changes new contract address, correct time must have passed
    /// @param _id Id of contract
    function approveContractChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inContractChange){
            revert EntryNotInChangeError(_id);
        }
        if (block.timestamp < (entries[_id].changeStartTime + entries[_id].waitPeriod)){// solhint-disable-line
            revert ChangeNotReadyError(block.timestamp, (entries[_id].changeStartTime + entries[_id].waitPeriod));
        }

        address oldContractAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = pendingAddresses[_id];
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        pendingAddresses[_id] = address(0);
        previousAddresses[_id] = oldContractAddr;

        emit ApproveContractChange(msg.sender, _id, oldContractAddr, entries[_id].contractAddr);
    }

    /// @notice Cancel pending change
    /// @param _id Id of contract
    function cancelContractChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inContractChange){
            revert EntryNotInChangeError(_id);
        }

        address oldContractAddr = pendingAddresses[_id];

        pendingAddresses[_id] = address(0);
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        emit CancelContractChange(msg.sender, _id, oldContractAddr, entries[_id].contractAddr);
    }

    /// @notice Starts the change for waitPeriod
    /// @param _id Id of contract
    /// @param _newWaitPeriod New wait time
    function startWaitPeriodChange(bytes4 _id, uint256 _newWaitPeriod) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (entries[_id].inContractChange){
            revert AlreadyInContractChangeError(_id);
        }

        pendingWaitTimes[_id] = _newWaitPeriod;

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inWaitPeriodChange = true;

        emit StartWaitPeriodChange(msg.sender, _id, _newWaitPeriod);
    }

    /// @notice Changes new wait period, correct time must have passed
    /// @param _id Id of contract
    function approveWaitPeriodChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inWaitPeriodChange){
            revert EntryNotInChangeError(_id);
        }
        if (block.timestamp < (entries[_id].changeStartTime + entries[_id].waitPeriod)){ // solhint-disable-line
            revert ChangeNotReadyError(block.timestamp, (entries[_id].changeStartTime + entries[_id].waitPeriod));
        }

        uint256 oldWaitTime = entries[_id].waitPeriod;
        entries[_id].waitPeriod = pendingWaitTimes[_id];
        
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        pendingWaitTimes[_id] = 0;

        emit ApproveWaitPeriodChange(msg.sender, _id, oldWaitTime, entries[_id].waitPeriod);
    }

    /// @notice Cancel wait period change
    /// @param _id Id of contract
    function cancelWaitPeriodChange(bytes4 _id) public onlyOwner {
        if (!entries[_id].exists){
            revert EntryNonExistentError(_id);
        }
        if (!entries[_id].inWaitPeriodChange){
            revert EntryNotInChangeError(_id);
        }

        uint256 oldWaitPeriod = pendingWaitTimes[_id];

        pendingWaitTimes[_id] = 0;
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        emit CancelWaitPeriodChange(msg.sender, _id, oldWaitPeriod, entries[_id].waitPeriod);
    }
}





abstract contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view virtual returns (bool);
}





contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "Not authorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}





contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}






abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) {
        if (!(setCache(_cacheAddr))){
            require(isAuthorized(msg.sender, msg.sig), "Not authorized");
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        virtual
        returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public payable virtual returns (bool);
}

contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}





contract DefisaverLogger {
    event RecipeEvent(
        address indexed caller,
        string indexed logName
    );

    event ActionDirectEvent(
        address indexed caller,
        string indexed logName,
        bytes data
    );

    function logRecipeEvent(
        string memory _logName
    ) public {
        emit RecipeEvent(msg.sender, _logName);
    }

    function logActionDirectEvent(
        string memory _logName,
        bytes memory _data
    ) public {
        emit ActionDirectEvent(msg.sender, _logName, _data);
    }
}





contract MainnetActionsUtilAddresses {
    address internal constant DFS_REG_CONTROLLER_ADDR = 0xF8f8B3C98Cf2E63Df3041b73f80F362a4cf3A576;
    address internal constant REGISTRY_ADDR = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
    address internal constant DFS_LOGGER_ADDR = 0xcE7a977Cac4a481bc84AC06b2Da0df614e621cf3;
    address internal constant SUB_STORAGE_ADDR = 0x1612fc28Ee0AB882eC99842Cde0Fc77ff0691e90;
}





contract ActionsUtilHelper is MainnetActionsUtilAddresses {
}








abstract contract ActionBase is AdminAuth, ActionsUtilHelper {
    event ActionEvent(
        string indexed logName,
        bytes data
    );

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    DefisaverLogger public constant logger = DefisaverLogger(
        DFS_LOGGER_ADDR
    );

    //Wrong sub index value
    error SubIndexValueError();
    //Wrong return index value
    error ReturnIndexValueError();

    /// @dev Subscription params index range [128, 255]
    uint8 public constant SUB_MIN_INDEX_VALUE = 128;
    uint8 public constant SUB_MAX_INDEX_VALUE = 255;

    /// @dev Return params index range [1, 127]
    uint8 public constant RETURN_MIN_INDEX_VALUE = 1;
    uint8 public constant RETURN_MAX_INDEX_VALUE = 127;

    /// @dev If the input value should not be replaced
    uint8 public constant NO_PARAM_MAPPING = 0;

    /// @dev We need to parse Flash loan actions in a different way
    enum ActionType { FL_ACTION, STANDARD_ACTION, FEE_ACTION, CHECK_ACTION, CUSTOM_ACTION }

    /// @notice Parses inputs and runs the implemented action through a proxy
    /// @dev Is called by the RecipeExecutor chaining actions together
    /// @param _callData Array of input values each value encoded as bytes
    /// @param _subData Array of subscribed vales, replaces input values if specified
    /// @param _paramMapping Array that specifies how return and subscribed values are mapped in input
    /// @param _returnValues Returns values from actions before, which can be injected in inputs
    /// @return Returns a bytes32 value through DSProxy, each actions implements what that value is
    function executeAction(
        bytes memory _callData,
        bytes32[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable virtual returns (bytes32);

    /// @notice Parses inputs and runs the single implemented action through a proxy
    /// @dev Used to save gas when executing a single action directly
    function executeActionDirect(bytes memory _callData) public virtual payable;

    /// @notice Returns the type of action we are implementing
    function actionType() public pure virtual returns (uint8);


    //////////////////////////// HELPER METHODS ////////////////////////////

    /// @notice Given an uint256 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamUint(
        uint _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (uint) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = uint(_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = uint256(_subData[getSubIndex(_mapType)]);
            }
        }

        return _param;
    }


    /// @notice Given an addr input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamAddr(
        address _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal view returns (address) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = address(bytes20((_returnValues[getReturnIndex(_mapType)])));
            } else {
                /// @dev The last two values are specially reserved for proxy addr and owner addr
                if (_mapType == 254) return address(this); //DSProxy address
                if (_mapType == 255) return DSProxy(payable(address(this))).owner(); // owner of DSProxy

                _param = address(uint160(uint256(_subData[getSubIndex(_mapType)])));
            }
        }

        return _param;
    }

    /// @notice Given an bytes32 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamABytes32(
        bytes32 _param,
        uint8 _mapType,
        bytes32[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (bytes32) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = (_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = _subData[getSubIndex(_mapType)];
            }
        }

        return _param;
    }

    /// @notice Checks if the paramMapping value indicated that we need to inject values
    /// @param _type Indicated the type of the input
    function isReplaceable(uint8 _type) internal pure returns (bool) {
        return _type != NO_PARAM_MAPPING;
    }

    /// @notice Checks if the paramMapping value is in the return value range
    /// @param _type Indicated the type of the input
    function isReturnInjection(uint8 _type) internal pure returns (bool) {
        return (_type >= RETURN_MIN_INDEX_VALUE) && (_type <= RETURN_MAX_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in return array value
    /// @param _type Indicated the type of the input
    function getReturnIndex(uint8 _type) internal pure returns (uint8) {
        if (!(isReturnInjection(_type))){
            revert SubIndexValueError();
        }

        return (_type - RETURN_MIN_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in sub array value
    /// @param _type Indicated the type of the input
    function getSubIndex(uint8 _type) internal pure returns (uint8) {
        if (_type < SUB_MIN_INDEX_VALUE){
            revert ReturnIndexValueError();
        }
        return (_type - SUB_MIN_INDEX_VALUE);
    }
}





contract StrategyModel {
        
    /// @dev Group of strategies bundled together so user can sub to multiple strategies at once
    /// @param creator Address of the user who created the bundle
    /// @param strategyIds Array of strategy ids stored in StrategyStorage
    struct StrategyBundle {
        address creator;
        uint64[] strategyIds;
    }

    /// @dev Template/Class which defines a Strategy
    /// @param name Name of the strategy useful for logging what strategy is executing
    /// @param creator Address of the user which created the strategy
    /// @param triggerIds Array of identifiers for trigger - bytes4(keccak256(TriggerName))
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    /// @param continuous If the action is repeated (continuos) or one time
    struct Strategy {
        string name;
        address creator;
        bytes4[] triggerIds;
        bytes4[] actionIds;
        uint8[][] paramMapping;
        bool continuous;
    }

    /// @dev List of actions grouped as a recipe
    /// @param name Name of the recipe useful for logging what recipe is executing
    /// @param callData Array of calldata inputs to each action
    /// @param subData Used only as part of strategy, subData injected from StrategySub.subData
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    struct Recipe {
        string name;
        bytes[] callData;
        bytes32[] subData;
        bytes4[] actionIds;
        uint8[][] paramMapping;
    }

    /// @dev Actual data of the sub we store on-chain
    /// @dev In order to save on gas we store a keccak256(StrategySub) and verify later on
    /// @param userProxy Address of the users smart wallet/proxy
    /// @param isEnabled Toggle if the subscription is active
    /// @param strategySubHash Hash of the StrategySub data the user inputted
    struct StoredSubData {
        bytes20 userProxy; // address but put in bytes20 for gas savings
        bool isEnabled;
        bytes32 strategySubHash;
    }

    /// @dev Instance of a strategy, user supplied data
    /// @param strategyOrBundleId Id of the strategy or bundle, depending on the isBundle bool
    /// @param isBundle If true the id points to bundle, if false points directly to strategyId
    /// @param triggerData User supplied data needed for checking trigger conditions
    /// @param subData User supplied data used in recipe
    struct StrategySub {
        uint64 strategyOrBundleId;
        bool isBundle;
        bytes[] triggerData;
        bytes32[] subData;
    }
}






contract StrategyStorage is StrategyModel, AdminAuth {

    Strategy[] public strategies;
    bool public openToPublic = false;

    error NoAuthToCreateStrategy(address,bool);
    event StrategyCreated(uint256 indexed strategyId);

    modifier onlyAuthCreators {
        if (adminVault.owner() != msg.sender && openToPublic == false) {
            revert NoAuthToCreateStrategy(msg.sender, openToPublic);
        }

        _;
    }

    /// @notice Creates a new strategy and writes the data in an array
    /// @dev Can only be called by auth addresses if it's not open to public
    /// @param _name Name of the strategy useful for logging what strategy is executing
    /// @param _triggerIds Array of identifiers for trigger - bytes4(keccak256(TriggerName))
    /// @param _actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param _paramMapping Describes how inputs to functions are piped from return/subbed values
    /// @param _continuous If the action is repeated (continuos) or one time
    function createStrategy(
        string memory _name,
        bytes4[] memory _triggerIds,
        bytes4[] memory _actionIds,
        uint8[][] memory _paramMapping,
        bool _continuous
    ) public onlyAuthCreators returns (uint256) {
        strategies.push(Strategy({
                name: _name,
                creator: msg.sender,
                triggerIds: _triggerIds,
                actionIds: _actionIds,
                paramMapping: _paramMapping,
                continuous : _continuous
        }));

        emit StrategyCreated(strategies.length - 1);

        return strategies.length - 1;
    }

    /// @notice Switch to determine if bundles can be created by anyone
    /// @dev Callable only by the owner
    /// @param _openToPublic Flag if true anyone can create bundles
    function changeEditPermission(bool _openToPublic) public onlyOwner {
        openToPublic = _openToPublic;
    }

    ////////////////////////////// VIEW METHODS /////////////////////////////////

    function getStrategy(uint _strategyId) public view returns (Strategy memory) {
        return strategies[_strategyId];
    }
    function getStrategyCount() public view returns (uint256) {
        return strategies.length;
    }

    function getPaginatedStrategies(uint _page, uint _perPage) public view returns (Strategy[] memory) {
        Strategy[] memory strategiesPerPage = new Strategy[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > strategies.length) ? strategies.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            strategiesPerPage[count] = strategies[i];
            count++;
        }

        return strategiesPerPage;
    }

}





contract MainnetCoreAddresses {
    address internal constant REGISTRY_ADDR = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
    address internal constant PROXY_AUTH_ADDR = 0x149667b6FAe2c63D1B4317C716b0D0e4d3E2bD70;
    address internal constant DEFISAVER_LOGGER = 0xcE7a977Cac4a481bc84AC06b2Da0df614e621cf3;

    address internal constant SUB_STORAGE_ADDR = 0x1612fc28Ee0AB882eC99842Cde0Fc77ff0691e90;
    address internal constant BUNDLE_STORAGE_ADDR = 0x223c6aDE533851Df03219f6E3D8B763Bd47f84cf;
    address internal constant STRATEGY_STORAGE_ADDR = 0xF52551F95ec4A2B4299DcC42fbbc576718Dbf933;

    address constant internal RECIPE_EXECUTOR_ADDR = 0x1D6DEdb49AF91A11B5C5F34954FD3E8cC4f03A86;
}





contract CoreHelper is MainnetCoreAddresses {
}









contract BundleStorage is StrategyModel, AdminAuth, CoreHelper {

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    StrategyBundle[] public bundles;
    bool public openToPublic = false;

    error NoAuthToCreateBundle(address,bool);
    error DiffTriggersInBundle(uint64[]);

    event BundleCreated(uint256 indexed bundleId);

    modifier onlyAuthCreators {
        if (adminVault.owner() != msg.sender && openToPublic == false) {
            revert NoAuthToCreateBundle(msg.sender, openToPublic);
        }

        _;
    }

    /// @dev Checks if the triggers in strategies are the same (order also relevant)
    /// @dev If the caller is not owner we do additional checks, we skip those checks for gas savings
    modifier sameTriggers(uint64[] memory _strategyIds) {
        if (msg.sender != adminVault.owner()) {
            Strategy memory firstStrategy = StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategy(_strategyIds[0]);

            bytes32 firstStrategyTriggerHash = keccak256(abi.encode(firstStrategy.triggerIds));

            for (uint256 i = 1; i < _strategyIds.length; ++i) {
                Strategy memory s = StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategy(_strategyIds[i]);

                if (firstStrategyTriggerHash != keccak256(abi.encode(s.triggerIds))) {
                    revert DiffTriggersInBundle(_strategyIds);
                }
            }
        }

        _;
    }

    /// @notice Adds a new bundle to array
    /// @dev Can only be called by auth addresses if it's not open to public
    /// @dev Strategies need to have the same number of triggers and ids exists
    /// @param _strategyIds Array of strategyIds that go into a bundle
    function createBundle(
        uint64[] memory _strategyIds
    ) public onlyAuthCreators sameTriggers(_strategyIds) returns (uint256) {

        bundles.push(StrategyBundle({
            creator: msg.sender,
            strategyIds: _strategyIds
        }));

        emit BundleCreated(bundles.length - 1);

        return bundles.length - 1;
    }

    /// @notice Switch to determine if bundles can be created by anyone
    /// @dev Callable only by the owner
    /// @param _openToPublic Flag if true anyone can create bundles
    function changeEditPermission(bool _openToPublic) public onlyOwner {
        openToPublic = _openToPublic;
    }

    ////////////////////////////// VIEW METHODS /////////////////////////////////

    function getStrategyId(uint256 _bundleId, uint256 _strategyIndex) public view returns (uint256) {
        return bundles[_bundleId].strategyIds[_strategyIndex];
    }

    function getBundle(uint _bundleId) public view returns (StrategyBundle memory) {
        return bundles[_bundleId];
    }
    function getBundleCount() public view returns (uint256) {
        return bundles.length;
    }

    function getPaginatedBundles(uint _page, uint _perPage) public view returns (StrategyBundle[] memory) {
        StrategyBundle[] memory bundlesPerPage = new StrategyBundle[](_perPage);
        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > bundles.length) ? bundles.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            bundlesPerPage[count] = bundles[i];
            count++;
        }

        return bundlesPerPage;
    }

}









contract SubStorage is StrategyModel, AdminAuth, CoreHelper {
    error SenderNotSubOwnerError(address, uint256);
    error SubIdOutOfRange(uint256, bool);

    event Subscribe(uint256 indexed subId, address indexed proxy, bytes32 indexed subHash, StrategySub subStruct);
    event UpdateData(uint256 indexed subId, bytes32 indexed subHash, StrategySub subStruct);
    event ActivateSub(uint256 indexed subId);
    event DeactivateSub(uint256 indexed subId);

    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    StoredSubData[] public strategiesSubs;

    /// @notice Checks if subId is init. and if the sender is the owner
    modifier onlySubOwner(uint256 _subId) {
        if (address(strategiesSubs[_subId].userProxy) != msg.sender) {
            revert SenderNotSubOwnerError(msg.sender, _subId);
        }
        _;
    }

    /// @notice Checks if the id is valid (points to a stored bundle/sub)
    modifier isValidId(uint256 _id, bool _isBundle) {
        if (_isBundle) {
            if (_id > (BundleStorage(BUNDLE_STORAGE_ADDR).getBundleCount() - 1)) {
                revert SubIdOutOfRange(_id, _isBundle);
            }
        } else {
            if (_id > (StrategyStorage(STRATEGY_STORAGE_ADDR).getStrategyCount() - 1)) {
                revert SubIdOutOfRange(_id, _isBundle);
            }
        }

        _;
    }

    /// @notice Adds users info and records StoredSubData, logs StrategySub
    /// @dev To save on gas we don't store the whole struct but rather the hash of the struct
    /// @param _sub Subscription struct of the user (is not stored on chain, only the hash)
    function subscribeToStrategy(
        StrategySub memory _sub
    ) public isValidId(_sub.strategyOrBundleId, _sub.isBundle) returns (uint256) {

        bytes32 subStorageHash = keccak256(abi.encode(_sub));

        strategiesSubs.push(StoredSubData(
            bytes20(msg.sender),
            true,
            subStorageHash
        ));

        uint256 currentId = strategiesSubs.length - 1;

        emit Subscribe(currentId, msg.sender, subStorageHash, _sub);

        return currentId;
    }

    /// @notice Updates the users subscription data
    /// @dev Only callable by proxy who created the sub.
    /// @param _subId Id of the subscription to update
    /// @param _sub Subscription struct of the user (needs whole struct so we can hash it)
    function updateSubData(
        uint256 _subId,
        StrategySub calldata _sub
    ) public onlySubOwner(_subId) isValidId(_sub.strategyOrBundleId, _sub.isBundle)  {
        StoredSubData storage storedSubData = strategiesSubs[_subId];

        bytes32 subStorageHash = keccak256(abi.encode(_sub));

        storedSubData.strategySubHash = subStorageHash;

        emit UpdateData(_subId, subStorageHash, _sub);
    }

    /// @notice Enables the subscription for execution if disabled
    /// @dev Must own the sub. to be able to enable it
    /// @param _subId Id of subscription to enable
    function activateSub(
        uint _subId
    ) public onlySubOwner(_subId) {
        StoredSubData storage sub = strategiesSubs[_subId];

        sub.isEnabled = true;

        emit ActivateSub(_subId);
    }

    /// @notice Disables the subscription (will not be able to execute the strategy for the user)
    /// @dev Must own the sub. to be able to disable it
    /// @param _subId Id of subscription to disable
    function deactivateSub(
        uint _subId
    ) public onlySubOwner(_subId) {
        StoredSubData storage sub = strategiesSubs[_subId];

        sub.isEnabled = false;

        emit DeactivateSub(_subId);
    }

    ///////////////////// VIEW ONLY FUNCTIONS ////////////////////////////

    function getSub(uint _subId) public view returns (StoredSubData memory) {
        return strategiesSubs[_subId];
    }

    function getSubsCount() public view returns (uint256) {
        return strategiesSubs.length;
    }
}




contract MainnetLiquityAddresses {
    address internal constant LUSD_TOKEN_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant LQTY_TOKEN_ADDRESS = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address internal constant PRICE_FEED_ADDRESS = 0x4c517D4e2C851CA76d7eC94B805269Df0f2201De;
    address internal constant BORROWER_OPERATIONS_ADDRESS = 0x24179CD81c9e782A4096035f7eC97fB8B783e007;
    address internal constant TROVE_MANAGER_ADDRESS = 0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2;
    address internal constant SORTED_TROVES_ADDRESS = 0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6;
    address internal constant HINT_HELPERS_ADDRESS = 0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0;
    address internal constant COLL_SURPLUS_POOL_ADDRESS = 0x3D32e8b97Ed5881324241Cf03b2DA5E2EBcE5521;
    address internal constant STABILITY_POOL_ADDRESS = 0x66017D22b0f8556afDd19FC67041899Eb65a21bb;
    address internal constant LQTY_STAKING_ADDRESS = 0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d;
    address internal constant LQTY_FRONT_END_ADDRESS = 0x76720aC2574631530eC8163e4085d6F98513fb27;
    
    address internal constant CB_MANAGER_ADDRESS = 0x57619FE9C539f890b19c61812226F9703ce37137;
    address internal constant BLUSD_ADDRESS = 0xB9D7DdDca9a4AC480991865EfEf82E01273F79C3;
    address internal constant BOND_NFT_ADDRESS = 0xa8384862219188a8f03c144953Cf21fc124029Ee;
    address internal constant BLUSD_AMM_ADDRESS = 0x74ED5d42203806c8CDCf2F04Ca5F60DC777b901c;
    address internal constant LUSD_3CRV_POOL_ADDRESS = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address internal constant CURVE_REGISTRY_SWAP_ADDRESS = 0x81C46fECa27B31F3ADC2b91eE4be9717d1cd3DD7;
}





interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}





interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}





interface IBondNFT is IERC721Enumerable {
    
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (BondExtraData memory);
    function tokenURI(uint256 _tokenID) external view returns (string memory);
}




interface ISwaps {

    ///@notice Perform an exchange using the pool that offers the best rate
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Does NOT check rates in factory-deployed pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);


    ///@notice Perform an exchange using a specific pool
    ///@dev Prior to calling this function, the caller must approve
    ///        this contract to transfer `_amount` coins from `_from`
    ///        Works for both regular and factory-deployed pools
    ///@param _pool Address of the pool to use for the swap
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _expected Minimum quantity of `_from` received
    ///        in order for the transaction to succeed
    ///@param _receiver Address to transfer the received tokens to
    ///@return uint256 Amount received
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);



    ///@notice Find the pool offering the best rate for a given swap.
    ///@dev Checks rates for regular and factory pools
    ///@param _from Address of coin being sent
    ///@param _to Address of coin being received
    ///@param _amount Quantity of `_from` being sent
    ///@param _exclude_pools A list of up to 8 addresses which shouldn't be returned
    ///@return Pool address, amount received
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        address[8] memory _exclude_pools
    ) external view returns (address, uint256);


    ///@notice Get the current number of coins received in an exchange
    ///@dev Works for both regular and factory-deployed pools
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_from` to be sent
    ///@return Quantity of `_to` to be received
    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amount Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_input_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);


    ///@notice Get the current number of coins required to receive the given amount in an exchange
    ///@param _pool Pool address
    ///@param _from Address of coin to be sent
    ///@param _to Address of coin to be received
    ///@param _amounts Quantity of `_to` to be received
    ///@return Quantity of `_from` to be sent
    function get_exchange_amounts(
        address _pool,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) external view returns (uint256[] memory);


    ///@notice Set calculator contract
    ///@dev Used to calculate `get_dy` for a pool
    ///@param _pool Pool address
    ///@return `CurveCalc` address
    function get_calculator(address _pool) external view returns (address);


    /// @notice Perform up to four swaps in a single transaction
    /// @dev Routing and swap params must be determined off-chain. This
    ///     functionality is designed for gas efficiency over ease-of-use.
    /// @param _route Array of [initial token, pool, token, pool, token, ...]
    ///     The array is iterated until a pool address of 0x00, then the last
    ///     given token is transferred to `_receiver`
    /// @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
    ///     values for the n'th pool in `_route`. The swap type should be 1 for
    ///     a stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3
    ///     for a cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying`,
    ///     5 for Polygon factory metapools `exchange_underlying`, 6-8 for
    ///     underlying coin -> LP token "exchange" (actually `add_liquidity`), 9 and 10
    ///     for LP token -> underlying coin "exchange" (actually `remove_liquidity_one_coin`)
    /// @param _amount The amount of `_route[0]` token being sent.
    /// @param _expected The minimum amount received after the final swap.
    /// @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for
    ///     Polygon meta-factories underlying swaps.
    /// @param _receiver Address to transfer the final output token to.
    /// @return Received amount of the final output token
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external payable returns (uint256);

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external payable returns (uint256);

    function get_exchange_multiple_amount(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount
    ) external view returns (uint256);
}





abstract contract IWETH {
    function allowance(address, address) public virtual view returns (uint256);

    function balanceOf(address) public virtual view returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}






library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "Eth send fail");
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}






interface ITroveManager {
    
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}





interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}





interface IPriceFeed {
    function lastGoodPrice() external pure returns (uint256);
    function fetchPrice() external returns (uint);
}





interface IHintHelpers {

    function getRedemptionHints(
        uint _LUSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedLUSDamount
        );

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed);

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint);

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint);
}





interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}




interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event EtherSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}




interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);
}





interface ILQTYStaking {

    // --- Events --
    
    event LQTYTokenAddressSet(address _lqtyTokenAddress);
    event LUSDTokenAddressSet(address _lusdTokenAddress);
    event TroveManagerAddressSet(address _troveManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, uint LUSDGain, uint ETHGain);
    event F_ETHUpdated(uint _F_ETH);
    event F_LUSDUpdated(uint _F_LUSD);
    event TotalLQTYStakedUpdated(uint _totalLQTYStaked);
    event EtherSent(address _account, uint _amount);
    event StakerSnapshotsUpdated(address _staker, uint _F_ETH, uint _F_LUSD);

    // --- Functions ---

    function setAddresses
    (
        address _lqtyTokenAddress,
        address _lusdTokenAddress,
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _activePoolAddress
    )  external;

    function stake(uint _LQTYamount) external;

    function unstake(uint _LQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external; 

    function increaseF_LUSD(uint _LQTYFee) external;  

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingLUSDGain(address _user) external view returns (uint);

    function stakes(address) external view returns (uint256);
}






interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    struct BondData {
        uint256 lusdAmount;
        uint64 claimedBLUSD; // In BLUSD units without decimals
        uint64 startTime;
        uint64 endTime; // Timestamp of chicken in/out event
        BondStatus status;
    }

    function lusdToken() external view returns (address);
    function bLUSDToken() external view returns (address);
    function curvePool() external view returns (address);
    function bammSPVault() external view returns (address);
    function yearnCurveVault() external view returns (address);

    function countChickenIn() external view returns (uint256);
    function countChickenOut() external view returns (uint256);

    // constants
    function INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL() external pure returns (int128);
    function CHICKEN_IN_AMM_FEE() external view returns (uint256);

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external  returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minLUSD) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) external view returns (uint256);
    function getBondData(uint256 _bondID) external view returns (BondData memory);
    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256);
    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256);
    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256);
    function getLUSDInBAMMSPVault() external view returns (uint256);
    function calcTotalYearnCurveVaultShareValue() external view returns (uint256);
    function calcTotalLUSDValue() external view returns (uint256);
    function getPendingLUSD() external view returns (uint256);
    function getAcquiredLUSDInSP() external view returns (uint256);
    function getAcquiredLUSDInCurve() external view returns (uint256);
    function getTotalAcquiredLUSD() external view returns (uint256);
    function getPermanentLUSD() external view returns (uint256);
    function getOwnedLUSDInSP() external view returns (uint256);
    function getOwnedLUSDInCurve() external view returns (uint256);
    function calcSystemBackingRatio() external view returns (uint256);
    function calcUpdatedAccrualParameter() external view returns (uint256);
    function getBAMMLUSDDebt() external view returns (uint256);
    function getOpenBondCount() external view returns (uint256);
    function getTreasury()
        external
        view
        returns (
            uint256 _pendingLUSD,
            uint256 _totalAcquiredLUSD,
            uint256 _permanentLUSD
        );
}















contract LiquityHelper is MainnetLiquityAddresses {
    using TokenUtils for address;

    uint constant public LUSD_GAS_COMPENSATION = 200e18;

    IPriceFeed constant public PriceFeed = IPriceFeed(PRICE_FEED_ADDRESS);
    IBorrowerOperations constant public BorrowerOperations = IBorrowerOperations(BORROWER_OPERATIONS_ADDRESS);
    ITroveManager constant public TroveManager = ITroveManager(TROVE_MANAGER_ADDRESS);
    ISortedTroves constant public SortedTroves = ISortedTroves(SORTED_TROVES_ADDRESS);
    IHintHelpers constant public HintHelpers = IHintHelpers(HINT_HELPERS_ADDRESS);
    ICollSurplusPool constant public CollSurplusPool = ICollSurplusPool(COLL_SURPLUS_POOL_ADDRESS);
    IStabilityPool constant public StabilityPool = IStabilityPool(STABILITY_POOL_ADDRESS);
    ILQTYStaking constant public LQTYStaking = ILQTYStaking(LQTY_STAKING_ADDRESS);
    IChickenBondManager constant public CBManager = IChickenBondManager(CB_MANAGER_ADDRESS);

    function withdrawStaking(uint256 _ethGain, uint256 _lusdGain, address _wethTo, address _lusdTo) internal {
        if (_ethGain > 0) {
            TokenUtils.depositWeth(_ethGain);
            TokenUtils.WETH_ADDR.withdrawTokens(_wethTo, _ethGain);
        }
        if (_lusdGain > 0) {
            LUSD_TOKEN_ADDRESS.withdrawTokens(_lusdTo, _lusdGain);
        }
    }
    
    function withdrawStabilityGains(uint256 _ethGain, uint256 _lqtyGain, address _wethTo, address _lqtyTo) internal {
        if (_ethGain > 0) {
            TokenUtils.depositWeth(_ethGain);
            TokenUtils.WETH_ADDR.withdrawTokens(_wethTo, _ethGain);
        }      
        if (_lqtyGain > 0) {
            LQTY_TOKEN_ADDRESS.withdrawTokens(_lqtyTo, _lqtyGain);
        }
    }
}





interface IBondNFTArtwork {
    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory);
}









contract ChickenBondsView is LiquityHelper {

    struct BondDataFull {
        uint256 bondID; // ERC721 token id
        uint256 lusdAmount; // Lusd amount entered in the bond
        uint64 claimedBLUSD; // In BLUSD units without decimals
        uint256 accruedBLUSD; // Amount of blusd accrued when in active phase
        uint256 maxAmountBLUSD; // Max cap amount of blusd the bond can accrue
        uint64 startTime; // Timestamp when bond is created
        uint64 endTime; // Timestamp of chicken in/out event
        IChickenBondManager.BondStatus status; // [nonExistent = 0, active = 1, chickenedOut = 2, chickenedIn = 3]
        string tokenURI; // json data of token image
    }

    struct ChickenBondsSystemInfo {
        uint256 totalPendingLUSD;
        uint256 totalReserveLUSD;
        uint256 totalPermanentLUSD;
        uint256 ownedLUSDInSP; // protocolOwnedLusdInStabilityPool
        uint256 ownedLUSDInCurve; // protocolLusdInCurve
        uint256 systemBackingRatio;
        uint256 accrualParameter;
        uint256 chickenInAMMFee;
        uint256 numPendingBonds;
        uint256 numChickenInBonds;
        uint256 numChickenOutBonds;
        uint256 bLUSDSupply;
    }

    function getBondFullInfo(uint256 _bondID) public view returns (BondDataFull memory bond) {
        IBondNFT bondNFT = IBondNFT(BOND_NFT_ADDRESS);

        IChickenBondManager.BondData memory bondData = CBManager.getBondData(_bondID);

        string memory tokenUri = bondNFT.tokenURI(_bondID);

        bond = BondDataFull({
            bondID: _bondID,
            lusdAmount: bondData.lusdAmount,
            claimedBLUSD: bondData.claimedBLUSD,
            accruedBLUSD: CBManager.calcAccruedBLUSD(_bondID),
            maxAmountBLUSD: CBManager.calcBondBLUSDCap(_bondID),
            startTime: bondData.startTime,
            endTime: bondData.endTime,
            status: bondData.status,
            tokenURI: tokenUri
        });
    }

    function getUsersBonds(address _userAddr) public view returns (BondDataFull[] memory bonds) {
        IBondNFT bondNFT = IBondNFT(BOND_NFT_ADDRESS);

        uint numTokens = bondNFT.balanceOf(_userAddr);
        bonds = new BondDataFull[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            uint256 bondID = bondNFT.tokenOfOwnerByIndex(_userAddr, i);

            bonds[i] = getBondFullInfo(bondID);
        }
    }

    function getSystemInfo() public view returns (ChickenBondsSystemInfo memory systemInfo) {
        (uint256 totalPendingLUSD, uint256 totalReserveLUSD, uint256 totalPermanentLUSD) = CBManager.getTreasury();

        systemInfo = ChickenBondsSystemInfo({
            totalPendingLUSD: totalPendingLUSD,
            totalReserveLUSD: totalReserveLUSD,
            totalPermanentLUSD: totalPermanentLUSD,
            ownedLUSDInSP: CBManager.getOwnedLUSDInSP(),
            ownedLUSDInCurve: CBManager.getOwnedLUSDInCurve(),
            systemBackingRatio: CBManager.calcSystemBackingRatio(),
            accrualParameter: CBManager.calcUpdatedAccrualParameter(),
            chickenInAMMFee: CBManager.CHICKEN_IN_AMM_FEE(),
            numPendingBonds: CBManager.getOpenBondCount(),
            numChickenInBonds: CBManager.countChickenIn(),
            numChickenOutBonds: CBManager.countChickenOut(),
            bLUSDSupply: IERC20(BLUSD_ADDRESS).totalSupply()
        });
    }
}






library Sqrt {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}











contract CBHelper is DSMath, MainnetLiquityAddresses {

    using Sqrt for uint256;

    uint64 public constant REBOND_STRATEGY_ID = 31; 

    struct CBInfo {
        uint256 chickenInAMMFee;
        uint256 accrualParameter;
        uint256 totalReserveLUSD;
        uint256 bLUSDSupply;
    }

    IChickenBondManager constant public CBManager = IChickenBondManager(CB_MANAGER_ADDRESS);

    /// @notice Calculates bLUSD price in Curve pool based on the amount we are swapping
    function getBLusdPriceFromCurve(uint256 _amount) public view returns (uint256) {
        address[9] memory routes;
        routes[0] = BLUSD_ADDRESS;
        routes[1] = BLUSD_AMM_ADDRESS;
        routes[2] = LUSD_3CRV_POOL_ADDRESS;
        routes[3] = LUSD_3CRV_POOL_ADDRESS;
        routes[4] = LUSD_TOKEN_ADDRESS;
        // rest is 0x0 by default

        uint256[3][4] memory swapParams;
        swapParams[0] = [uint256(0), uint256(1), uint256(3)];
        swapParams[1] = [uint256(0), uint256(0), uint256(9)];
        swapParams[2] = [uint256(0), uint256(0), uint256(0)];
        swapParams[3] = [uint256(0), uint256(0), uint256(0)];

        uint256 outputAmount = ISwaps(CURVE_REGISTRY_SWAP_ADDRESS).get_exchange_multiple_amount(
            routes,
            swapParams,
            _amount
        );

        return wdiv(outputAmount, _amount);
    }

    /// @notice Calculates 'optimal' amount of LUSD for an lusdAmount to accrue based on the market price
    function getOptimalLusdAmount(uint256 _bLUSDCap, uint256 _accruedBLUSD) public view returns (uint256, uint256) {
        CBInfo memory systemInfo = getCbInfo();

        uint256 minimalBLUSDForPriceFetching = 50 * 1e18;
        _accruedBLUSD = _accruedBLUSD > minimalBLUSDForPriceFetching ? _accruedBLUSD : minimalBLUSDForPriceFetching;

        uint256 marketPrice = getBLusdPriceFromCurve(_accruedBLUSD);

        uint256 optimalRebondTime = _getOptimalRebondTime(systemInfo, marketPrice);

        if (optimalRebondTime == 0) {
            return (0, 0);
        }

        uint256 res = wmul(
            wdiv(
                wmul(_bLUSDCap, optimalRebondTime),
                (systemInfo.accrualParameter + optimalRebondTime)
            ),
            marketPrice * 10**18
        );

        return (res / 1e18, marketPrice);
    }

    /// @notice Internal function calculated optimal wait time for the user to accrue bLUSD
    function _getOptimalRebondTime(CBInfo memory systemInfo, uint256 _marketPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 marketPricePremium = _calcMarketPricePremium(systemInfo, _marketPrice);

        uint256 feeAmount = systemInfo.chickenInAMMFee * marketPricePremium;
        uint256 premiumMinusFee = (marketPricePremium * 1e18) - feeAmount;

        uint256 premiumSqrt = premiumMinusFee.sqrt();
        uint256 premiumScaled = (premiumMinusFee / 1e18);

        if (premiumScaled <= 1e18) {
            return 0;
        }

        uint256 res = wmul(
            systemInfo.accrualParameter,
            wmul((premiumSqrt + 1e18), wdiv(1e18, (premiumScaled - 1e18)))
        );

        return res;
    }

    /// @notice Calculates market price premium based on the floor price and the current market price
    function _calcMarketPricePremium(CBInfo memory systemInfo, uint256 _marketPrice)
        public
        pure
        returns (uint256 marketPricePremium)
    {
        uint256 floorPrice = wdiv(systemInfo.totalReserveLUSD, systemInfo.bLUSDSupply);
        marketPricePremium = wdiv(_marketPrice, floorPrice);
    }

    /// @notice View helper for calculating rebond time without input params
    function getOptimalRebondTime() public view returns (uint256) {
        CBInfo memory systemInfo = getCbInfo();
        uint256 marketPrice = getBLusdPriceFromCurve(1000 * 1e18);

        return _getOptimalRebondTime(systemInfo, marketPrice);
    }

    /// @notice Returns info about cb system needed for the calculations
    function getCbInfo() public view returns (CBInfo memory systemInfo) {
        (, uint256 totalReserveLUSD, ) = CBManager.getTreasury();

        systemInfo = CBInfo({
            totalReserveLUSD: totalReserveLUSD,
            accrualParameter: CBManager.calcUpdatedAccrualParameter(),
            chickenInAMMFee: CBManager.CHICKEN_IN_AMM_FEE(),
            bLUSDSupply: IERC20(BLUSD_ADDRESS).totalSupply()
        });
    }

    function formatRebondSub(uint256 _newSubId, uint256 _bondID) public pure returns (StrategyModel.StrategySub memory rebondSub) {
        rebondSub.strategyOrBundleId = REBOND_STRATEGY_ID;
        rebondSub.isBundle = false;

        bytes memory triggerData = abi.encode(_bondID);
        rebondSub.triggerData =  new bytes[](1);
        rebondSub.triggerData[0] = triggerData;

        rebondSub.subData =  new bytes32[](4);
        rebondSub.subData[0] = bytes32(_newSubId);
        rebondSub.subData[1] = bytes32(_bondID);
        rebondSub.subData[2] = bytes32(uint256(uint160(BLUSD_ADDRESS)));
        rebondSub.subData[3] = bytes32(uint256(uint160(LUSD_TOKEN_ADDRESS)));
    }
}








contract CBUpdateRebondSub is ActionBase, CBHelper {

    error ImpactTooHigh(uint256, uint256);

    /// @param subId Id of the sub we are changing (user must be owner)
    /// @param bondId Id of the chicken bond NFT we just created
    struct Params {
        uint256 subId;
        uint256 bondId;
    }

    /// @inheritdoc ActionBase
    function executeAction(
        bytes memory _callData,
        bytes32[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public virtual override payable returns (bytes32) {
        Params memory params = parseInputs(_callData);

        params.subId = _parseParamUint(
            params.subId,
            _paramMapping[0],
            _subData,
            _returnValues
        );

        params.bondId = _parseParamUint(
            params.bondId,
            _paramMapping[1],
            _subData,
            _returnValues
        );

        updateRebondSub(params, uint256(_subData[1]));

        return(bytes32(params.subId));
    }

    function executeActionDirect(bytes memory _callData) public override payable {
        Params memory params = parseInputs(_callData);

        updateRebondSub(params, 0);
    }

    /// @inheritdoc ActionBase
    function actionType() public virtual override pure returns (uint8) {
        return uint8(ActionType.STANDARD_ACTION);
    }

    //////////////////////////// ACTION LOGIC ////////////////////////////

    function updateRebondSub(Params memory _params, uint256 _previousBondId) internal {
        if (_previousBondId != 0) {
            uint256 previousBondLUSDDeposited = CBManager.getBondData(_previousBondId).lusdAmount;
            uint256 newBondLUSDDeposited = CBManager.getBondData(_params.bondId).lusdAmount;

            if (newBondLUSDDeposited <= previousBondLUSDDeposited) {
                revert ImpactTooHigh(previousBondLUSDDeposited, newBondLUSDDeposited);
            }
        }

        StrategyModel.StrategySub memory rebondSub = formatRebondSub(_params.subId, _params.bondId);

        SubStorage(SUB_STORAGE_ADDR).updateSubData(_params.subId, rebondSub);
    }

    function parseInputs(bytes memory _callData) public pure returns (Params memory params) {
        params = abi.decode(_callData, (Params));
    }
}
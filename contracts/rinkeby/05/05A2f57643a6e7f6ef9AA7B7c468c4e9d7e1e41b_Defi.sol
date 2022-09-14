// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        //require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20Upgradeable.sol";

contract Defi is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC20Upgradeable {
    using SafeMath for uint256;

    mapping (address => bool) private _iswhitelistAddress;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromAutoLiquidity;
    mapping (address => bool) private _isBlackListed;

    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    
    string private _name;
    string private _symbol; 
    uint8 private  _decimals;
    
    uint256 private _taxFee;
    uint256 private _buyTax; 
    uint256 private _sellTax; 
    uint256 private _transferTax;
    uint256 private _percentageforPool;
    uint256 private _percentageForOwner;

    uint256 private _minTokenBalance;

    bool private _isTradeable;
    
    // auto liquidity
    bool private _swapAndLiquifyEnabled;
    bool _inSwapAndLiquify;
    IUniswapV2Router02 private _uniswapV2Router;
    address            private _uniswapV2Pair;

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier isTradeable {
        require(_isTradeable,"Trading have been paused");
        _;
    }
    constructor() {
        _disableInitializers();
    }
    function initialize(address cOwner) initializer public {
        
        _name     = "Defi";
        _symbol   = "DEFI";
        _decimals = 18;
        _buyTax        = 7;
        _sellTax       = 4;
        _transferTax   = 3;
        
        _percentageforPool = 20;
        _percentageForOwner = 80;
        _minTokenBalance = 1 * 10**18;
        _swapAndLiquifyEnabled = true;
        _maxSupply = 100000000 * 10**18;

        transferOwnership(cOwner);
        _iswhitelistAddress[owner()]        = true;
        _iswhitelistAddress[address(this)]  = true;
        
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _uniswapV2Router = uniswapV2Router;
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        // exclude system contracts
       
        _isExcludedFromAutoLiquidity[_uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)] = true;

        _isTradeable = true;
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function mint(address account, uint256 amount) public onlyOwner{
        _mint(account, amount);
    }

    function isBlackListed(address account) public view returns(bool){
        return _isBlackListed[account];
    }
    
    function removeFromBlacklist(address account) public onlyOwner {
        _isBlackListed[account]= false;
    }

    function blackList(address account) public onlyOwner{
        _isBlackListed[account]= true;
    }

    function MaxSupply()external view returns(uint256){
        return _maxSupply;
    }

    function getTotalSupply()external view returns(uint256){
        return _totalSupply;
    }

    function getMinTokenBalance() external view returns(uint256){
        return _minTokenBalance; 
    }

    function setMinTokenBalance(uint256 mintokenBalance) external onlyOwner{
        _minTokenBalance = mintokenBalance;
    }

    function setLiquidityPercentageforPool(uint256 percent) external onlyOwner{
        _percentageforPool = percent;
    }

    function getLiquidityPercentageforPool() external view returns(uint256) {
        return _percentageforPool;
    }
    function setPercentageForOwner(uint256 percent) external onlyOwner{
        _percentageForOwner = percent;
    }
    function getPercentageForOwner () external view returns(uint256){
        return _percentageForOwner;
    }
    function getBuyTax() external view returns(uint256){
        return _buyTax;
    }

    function getSellTax() external view returns(uint256){
        return _sellTax;
    }

    function getTransferTax() external view returns(uint256){
        return _transferTax;
    }

    function setSwapAndLiquifyEnabled(bool e) public onlyOwner {
        _swapAndLiquifyEnabled = e;
    }

    function pause () public onlyOwner {
        _isTradeable = false;
    }

    function unpause () public onlyOwner {
        _isTradeable = true;
    }
    
    receive() external payable {}

    function setUniswapRouter(address r) external onlyOwner {
        _uniswapV2Router = IUniswapV2Router02(r);
    }

    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee       = calculateFee(tAmount, _taxFee);
        uint256 tTransferAmount = tAmount.sub(tFee);
       // tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, 0);
    }

    function calculateFee(uint256 amount, uint256 fee) private pure returns (uint256) {
        return amount.mul(fee).div(100);
    }
    
    function isWhiteListUser(address account) public view returns(bool) {
        return _iswhitelistAddress[account];
    }

    function SetWhiteListUser(address account) public onlyOwner {
        _iswhitelistAddress[account] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount, uint256 amount2
    ) internal override{
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(!_isBlackListed[from] && !_isBlackListed[to],"sender or recipient is BOT");


        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool isOverMinTokenBalance = contractTokenBalance >= _minTokenBalance;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        if (_iswhitelistAddress[from] || _iswhitelistAddress[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        uint256 tokenShareForOwner = (contractTokenBalance * _percentageForOwner)/100;
        uint256 tokenShareForLiquidity = (contractTokenBalance * _percentageforPool)/100;
        uint256 initialBalance = address(this).balance;
        swapTokensForBnb(tokenShareForOwner);
        payable(owner()).transfer(address(this).balance - initialBalance);

        // split contract balance into halves
        uint256 half      = tokenShareForLiquidity.div(2);
        uint256 otherHalf = tokenShareForLiquidity.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
    }
    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        //uint256 previousTaxFee;      //= _taxFee;

        if(sender == _uniswapV2Pair){
            _taxFee = _buyTax + _transferTax;
        }
        else if(recipient == _uniswapV2Pair){
            _taxFee = _sellTax + _transferTax;
        }
        else{
            _taxFee = _transferTax;
        }
        
        if (!takeFee) {
            _taxFee       = 0;
        }
        _transferBothExcluded(sender, recipient, amount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee,) = _getTValues(tAmount);

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _balances[address(this)] += tFee;
    }

    function setTaxes(uint256 buyTax, uint256 sellTax, uint256 transferTax) public onlyOwner{
        uint256 totalTax = buyTax + sellTax + transferTax;
        if(totalTax > 20){
            revert("Please Enter Taxes Under 20%");
        }else{
            _buyTax = buyTax;
            _sellTax = sellTax;
            _transferTax = transferTax;
        }
    }
}
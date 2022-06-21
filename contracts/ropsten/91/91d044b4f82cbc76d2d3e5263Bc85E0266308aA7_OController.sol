// SPDX-License-Identifier: MIT
/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

import "./utils/Addons.sol";
import "./interfaces/IOToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";



contract OController is OwnableUpgradeable, Addons {
    // interfaces
    OTokenInterface OToken;

    // state variables
    bytes[] public batches;
    bytes[] public burnings;
    uint256 public batchesCount;
    bool public batchesMigrated;
    uint256 private tokensBurned;
    uint256 private tokensMinted;
    uint256 public burningsAmount;
    address public burningAddress;

    // mappings
    mapping(address => bool) public managers;
    mapping(address => mapping(string => bool)) public serviceProvidersWhitelist;
    mapping(address => uint) public burningBalanceOf;

    struct Burning {
        address user;
        address vaultingCompany;
        uint256 amount;
        Order order;
    }

    struct VaultSignedData {
        address vaultingCompany;
        uint256 olgcCount;
        Order order;
    }

    // structs
    struct Batch {
        string batchId;
        Order[] orders;
        uint256 ordersCount;
        uint256 oTokensMinted;
        ProviderConfirmations[] providers;
        MintingBase[] minting;
        uint256 providersCount;
        uint256 timestamp;
    }

    struct Order {
        string name;
        string weightOZ;
    }

    struct Service {
        string name;
        address provider;
    }

    struct Minting {
        address[] receiver;
        uint256[] amount;
    }

    struct MintingBase {
        Order order;
        Minting _minting;
    }

    struct ProviderConfirmations {
        string batchId;
        Order[] orders;
        address minter;
        string role;
        bytes data;
        bytes signature;
    }

    struct adminDataStruct {
        bytes32[] hashes;
        string batchId;
        MintingBase[] _minting;
    }

    // events
    event TokensMintingEvent(address[] addresses, uint256[] amount, bytes32 hash, string batchId, string orderId);
    event BatchEvent(uint256 amount, bytes32 hash, Batch batch);
    event Burned(address _user, uint256 _value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address token, address _burningAddress, uint256 minted, uint256 burned) public initializer {
        batchesCount = 0;
        OToken = OTokenInterface(token);
        batchesMigrated = false;
        tokensMinted = minted;
        tokensBurned = burned;
        burningAddress = _burningAddress;
        __Ownable_init();
    }

    // Modifiers
    modifier canBurn() {
        require(msg.sender == burningAddress, "only burningAddress wallet is allowed");
        _;
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(OToken), "Only Token contract is allowed");
        _;
    }

    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }

    // External functions

    function bulkAddManagers(bytes calldata data)
    external onlyOwner returns (bool status)
    {
        address[] memory managersArray = abi.decode(data, (address[]));
        for (uint8 i = 0; i < managersArray.length; i++) {
            managers[managersArray[i]] = true;
        }
        return true;
    }

    /**
     * @notice Function called by token contract wherever tokens are deposited to this contract
     * @dev Only token contract can call.
     * @param _from The number of tokens to be burned
     * @param _value The user corresponding to which tokens are burned
     * @param data The data supplied by token contract. It will be ignored
     */
    function tokenFallback(address _from, uint _value, bytes calldata data) external onlyTokenContract {
        burningBalanceOf[_from] = burningBalanceOf[_from] + _value;
    }

    /**
     * @notice Burns the tokens from users account for physical redemption
     * @dev The amount of tokens burned must be less than or equal to token deposited by user
     * @param _burning The number of tokens to be burned and order data
     * @param _signature The user corresponding to which tokens are burned
     * @return bool true in case of successful burn
     */
    function burnTokens(bytes calldata _burning, bytes calldata _signature) external canBurn returns(bool){
        Burning memory b;
        b = abi.decode(_burning, (Burning));

        VaultSignedData memory v = VaultSignedData(b.vaultingCompany, b.amount, b.order);

        bytes32 _message = keccak256(abi.encode(v));
        require(b.vaultingCompany == getSigner(_message, _signature), "Wrong signer");
        require(burningBalanceOf[b.user] > 0 && burningBalanceOf[b.user] >= b.amount, "Wrong user or amount to burn");
        burnings.push(abi.encode(b));
        require(OToken.burn(b.amount, bytes32ToString(_message), b.order.name), "Burning failure");
        burningBalanceOf[b.user] = burningBalanceOf[b.user] - b.amount;
        tokensBurned = tokensBurned + b.amount;
        burningsAmount = burningsAmount + 1;

        emit Burned(b.user, b.amount);
        return true;
    }

    /**
     * @notice Add new provider to the system
     * @dev Check if signer exists in managers mapping and add new provider
     * @param _role provider role
     * @param _provider provider address
     * @param _signature Manager wallet signature
     */
    function addProvider(string calldata _role, address _provider, bytes calldata _signature) external returns (bool status) {
        bytes32 _message = keccak256(abi.encode(_role, _provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        require(!serviceProvidersWhitelist[_provider][_role], "Service already exists");
        serviceProvidersWhitelist[_provider][_role] = true;
        return true;
    }

    /**
     * @notice Remove provider from the system
     * @dev Check if signer exists in managers mapping and delete existing provider
     * @param _role provider role
     * @param _provider provider address
     * @param _signature Manager wallet signature
     */
    function removeProvider(string calldata _role, address _provider, bytes calldata _signature) external returns (bool status) {
        bytes32 _message = keccak256(abi.encode(_role, _provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        require(serviceProvidersWhitelist[_provider][_role], "Service not exists");
        serviceProvidersWhitelist[_provider][_role] = false;
        return true;
    }

    /**
     * @notice Replace provider function
     * @dev Check if signer exists in managers mapping and delete existing provider if it's exists
       and add new provider if it's not added to the mapping
     * @param data encoded array of Service tuple
     * @param _signature Manager wallet signature
     */
    function replaceProvider(bytes calldata data, bytes calldata _signature)
        external returns (bool status)
    {
        bytes32 _message = keccak256(data);
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        Service[] memory providersArray = abi.decode(data, (Service[]));
        for (uint8 i = 0; i < providersArray.length; i++) {
            if(serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name]) {
                serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = false;
            } else {
                serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = true;
            }

        }
        return true;
    }


    /**
     * @notice Bulk add providers function
     * @dev Check if signer exists in managers mapping and add new providers
     * @param data encoded array of Service tuple
     * @param _signature Manager wallet signature
     */
    function bulkAddProviders(bytes calldata data, bytes calldata _signature)
    external returns (bool status)
    {
        bytes32 _message = keccak256(data);
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        Service[] memory providersArray = abi.decode(data, (Service[]));
        for (uint8 i = 0; i < providersArray.length; i++) {
            serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = true;
        }
        return true;
    }

    /**
     * @notice Execute OTokens minting process validations
     * @dev Encode payload data and perform providers and minting data validations
     * @param adminData encoded adminDataStruct tuple
     * @param providersData encoded array of ProviderConfirmations tuple
     * @param ordersList encoded array of Order tuple
     * @param _sig Manager wallet signature
     */
    function execMinting(
        bytes calldata adminData,
        bytes calldata providersData,
        bytes calldata ordersList,
        bytes calldata _sig
    ) external {
        ProviderConfirmations[] memory providersArray = abi.decode(providersData, (ProviderConfirmations[]));
        adminDataStruct memory admin = abi.decode(adminData, (adminDataStruct));
        bytes32 _message = keccak256(abi.encode(admin.batchId));
        require(validManagerOrAdmin(_sig, _message), "Caller not allowed");
        Order[] memory orders = abi.decode(ordersList, (Order[]));
        Batch memory batch;
        batch.batchId = admin.batchId;
        batch.orders = orders;
        require(admin.hashes.length == providersArray.length, "Wrong amount of confirmations");
        verifyProviders(providersArray, admin.hashes);
        batch.providers = providersArray;
        batch.ordersCount = batch.orders.length;
        batch.providersCount = batch.providers.length;

        require(_mint(admin._minting, keccak256(encodeTightlyPacked(admin.hashes)), batch), "something went wrong");
    }

    // Public functions

    /**
     * @notice update burning wallet address. This address will be responsible for burning tokens
     * @dev Only owner can call
     * @param _burningAddress The address that is allowed to burn tokens from suspense wallet
     * @return Bool value
     */
    function updateBurningAddress(address _burningAddress)
    public
    onlyOwner
    onlyNonZeroAddress(_burningAddress)
    returns (bool)
    {
        burningAddress = _burningAddress;
        return true;
    }

    /**
     * @notice manually add batches
     * @dev Only owner can call
     * @param _batches array of Batch structs
     * @return Bool value
     */
    function addBatches(bytes calldata _batches) public onlyOwner returns(bool) {
        require(!batchesMigrated, "Batches already migrated");
        batchesMigrated = true;
        Batch[] memory _b = abi.decode(_batches, (Batch[]));
        for (uint o=0; o<_b.length;o++) {
            writeStore(_b[o]);
            batchesCount = batchesCount + 1;
        }
        return true;
    }

    /**
     * @notice Add new manager to the system
     * @param _manager Manager wallet address
     * @return status
     */
    function addManager(address _manager) public onlyOwner returns (bool status) {
        require(!managers[_manager], "Manager already added");
        managers[_manager] = true;
        status = true;
    }

    /**
     * @notice Remove manager from the system
     * @param _manager Manager wallet address
     * @return status
     */
    function removeManager(address _manager) public onlyOwner returns (bool status) {
        require(managers[_manager], "Manager already added");
        managers[_manager] = false;
        status = true;
    }

    /**
     * @notice Owner can transfer out any accidentally sent ERC20 tokens accept OTokens
     * @param _tokenAddress The contract address of ERC-20 compitable token
     * @param _value The number of tokens to be transferred to owner
     */
    function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool) {
        require (_tokenAddress != address(OToken),"Can not withdraw OTs");
        IERC20Upgradeable(_tokenAddress).transfer(owner(), _value);
        return true;
    }

    // View functions

    /**
     * @notice Manager signature validator
     * @dev Check if signer exists in managers mapping
     * @param _signature Manager wallet signature
     * @param _message Manager signed message
     * @return Bool value
     */
    function validManagerOrAdmin(bytes calldata _signature, bytes32 _message) public view returns (bool) {
        return (msg.sender == owner() || managers[getSigner(_message, _signature)]);
    }

    function getBatch(uint256 id) public view returns(Batch memory b){
        return abi.decode(batches[id], (Batch));
    }

    function getBurnings(uint256 id) public view returns(Burning memory b){
        return abi.decode(burnings[id], (Burning));
    }

    function getTotalBurned() public view returns(uint256){
        return tokensBurned;
    }

    function getTotalMinted() public view returns(uint256){
        return tokensMinted;
    }

    // Internal functions

    function verifyHashes(bytes32[] memory hashes, bytes32 msgHash) internal pure returns(bool exists) {
        exists = false;
        for(uint8 h=0; h < hashes.length; h++) {
            if(hashes[h] == msgHash) {
                exists = true;
            }
        }
    }

    function verifyProviders(ProviderConfirmations[] memory providersArray, bytes32[] memory hashes) internal view {

        for (uint8 i = 0; i < providersArray.length; i++) {
            bytes32 msgHash = keccak256(abi.encode(
                    providersArray[i].batchId,
                    providersArray[i].minter,
                    providersArray[i].role
                ));
            bool exists = false;
            address signer = getSigner(
                msgHash,
                providersArray[i].signature
            );
            require(
                serviceProvidersWhitelist[signer][providersArray[i].role],
                "Address is not whitelisted"
            );
            exists = verifyHashes(hashes, msgHash);
            require(exists, "one of the messages is wrong");

        }
    }

    /**
     * @notice Execute OTokens minting process
     * @dev Encode payload data and mint tokens
     * @param _minting encoded MintingBase tuple
     * @param orderHash keccak256 hash of providers data hashes
     * @param batch Batch struct that contain current operation data
     */
    function _mint(MintingBase[] memory _minting, bytes32 orderHash, Batch memory batch) internal returns(bool) {
        require(_minting.length == batch.orders.length, "Orders count not match");
        MintingBase[] memory mintArray = _minting;
        for (uint i = 0; i < mintArray.length; i++) {
            require(OToken.bulkMint(mintArray[i]._minting.receiver, mintArray[i]._minting.amount, bytes32ToString(orderHash), mintArray[i].order.name), "something went wrong with minting");
            for(uint m =0; m < mintArray[i]._minting.amount.length; m++) {
                batch.oTokensMinted += mintArray[i]._minting.amount[m];
            }
            emit TokensMintingEvent(mintArray[i]._minting.receiver, mintArray[i]._minting.amount, orderHash, batch.batchId, mintArray[i].order.name);
        }
        batch.minting = _minting;
        batchesCount = batchesCount + 1;
        batch.timestamp = block.timestamp;
        emit BatchEvent(batch.oTokensMinted, orderHash, batch);

        writeStore(batch);
        return true;
    }

    function writeStore(Batch memory batch) internal {
        tokensMinted += batch.oTokensMinted;
        batches.push(abi.encode(batch));
    }

}

// SPDX-License-Identifier: MIT

/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

abstract contract Addons {

    /* @notice Find signer
     * @param message The message that user signed
     * @return address Signer of message
     */
    function getSigner(bytes32 message, bytes memory _signature)
    public
    pure
    returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        address signer = ecrecover(prefixedHash, v, r, s);
        return signer;
    }

    /* @notice Split signature to r s v
     * @param sig signature
     */
    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /* @notice Convert bytes32 to bytes type
     * @param _bytes32 The message that need to convert
     * @return bytesArray converted bytes
     */
    function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory){
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return bytesArray;
    }

    /* @notice Convert bytes32 to string type
     * @param _bytes32 The message that need to convert
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory){
        bytes memory bytesArray = bytes32ToBytes(_bytes32);
        return string(bytesArray);
    }

    /* @notice encode array of hashes
     * @param hashes array of bytes32
     * @return output encoded array
     */
    function encodeTightlyPacked(bytes32[] memory hashes) public pure returns(bytes memory output) {
        for (uint256 i = 0; i < hashes.length; i++) {
            output = abi.encodePacked(output, hashes[i]);
        }
        return output;
    }

}

// SPDX-License-Identifier: MIT
/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

interface OTokenInterface {

    function mint(address _to, uint256 _value, string memory _sawtoothHash, string memory _orderId)
    external returns (bool);
    function bulkMint (address[] memory _addressArr, uint256[] memory _amountArr, string memory _sawtoothHash, string memory _orderId)
    external returns (bool);
    function burn(uint256 amount, string memory hash, string memory order) external returns(bool);
    function transfer(address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
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
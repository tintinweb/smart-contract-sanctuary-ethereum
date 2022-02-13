/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: contracts/PublicPrivateVoucherMinter.sol



pragma solidity ^0.8.0;




interface IMintTo {
    function mintTo(address to, uint256 amount) external; // to be implement by subclass
}

contract PublicPrivateVoucherMinter is Ownable {    

    // event to log mint detail
    event PublicMint (address _address, uint256 _amount, uint256 _value);
    event PrivateMint(address _address, uint256 _amount, uint256 _value);
    event VoucherMint(address _address, uint256 _amount);

    event MinterCreated(address _address);

    // event to log voucher address
    event VoucherCreated(address[] _address, uint256[] _amount);
    event VoucherDeleted(address[] _address);

    bool _initialize;
    
    // Sale active control
    bool public isPublicMintActive;       // can call publicMint only when isPublicMintActive is true
    bool public isPrivateMintActive;      // can call privateMint only when isPrivateMintActive is true
    bool public isVoucherMintActive;      // can call voucherMint only when isVoucherMintActive is true

    uint256 public publicMintPrice;       // price for publicMint
    uint256 public privateMintPrice;      // price for privateMint
    uint256 public maxPublicMintAmount;   // maximum amount per publicMint transaction
    uint256 public maxPrivateMintAmount;  // maximum amount per privateMint transaction
    uint256 public maxPublicRoundSupply;  // maximum supply for current public round
    uint256 public maxPrivateRoundSupply; // maximum supply for current private round
    
    // Sale counter
    uint256 public currentPublicRoundSold;
    uint256 public currentPrivateRoundSold;
    uint256 public pastPublicRoundSold;
    uint256 public pastPrivateRoundSold;
    uint256 public totalVoucherClaimed;
    uint256 public totalUnclaimedVoucher;

    // Whitelisted address
    mapping(address => bool)    private _whitelisted;   // whitelisted address for private mint
    mapping(address => uint256) private _voucherAmount; // unclaimed voucher amount for the address
    
    // Operator
    address private _operator; // address of operator who can set parameter of this contract
    address private _mintedAddress; // address of the contract to call mintTo
    address private _withdrawAddress; // address to withdraw the mintAmount

    constructor (address mintedAddress) {
        initialize(mintedAddress, _msgSender(), _msgSender());
    }

    function initialize(address mintedAddress, address owner, address operator) public {
        require(!_initialize,"Already initialize");
        _mintedAddress = mintedAddress;
        _withdrawAddress = owner;
        _operator = operator;
    }

    function status() external view returns (uint256[] memory) {
        uint256[] memory data = new uint256[](15);
        data[0] = isPublicMintActive  ? 1 : 0;
        data[1] = isPrivateMintActive ? 1 : 0;
        data[2] = isVoucherMintActive ? 1 : 0;
        data[3] = publicMintPrice;
        data[4] = privateMintPrice;
        data[5] = maxPublicMintAmount;
        data[6] = maxPrivateMintAmount;
        data[7] = maxPublicRoundSupply;
        data[8] = maxPrivateRoundSupply;
        data[9] = currentPublicRoundSold;
        data[10] = currentPrivateRoundSold;
        data[11] = pastPublicRoundSold;
        data[12] = pastPrivateRoundSold;
        data[13] = totalVoucherClaimed;
        data[14] = totalUnclaimedVoucher;
        return data;
    }

    function setMintedAddress(address mintedAddress) external onlyOwner {
        _mintedAddress = mintedAddress;
    }

    function togglePublicMintActive() external onlyOwnerAndOperator {
        require (publicMintPrice > 0, "Public Mint Price is zero");
        isPublicMintActive = !isPublicMintActive;
        if (isPublicMintActive) {
            pastPublicRoundSold += currentPublicRoundSold;
            currentPublicRoundSold = 0;                     
        }
    }

    function togglePrivateMintActive() external onlyOwnerAndOperator {
        require (privateMintPrice > 0, "Private Mint Price is zero");
        isPrivateMintActive = !isPrivateMintActive;
        if (isPrivateMintActive) {
            pastPrivateRoundSold += currentPrivateRoundSold;
            currentPrivateRoundSold = 0;
        }
    }

    function totalSold() external view returns (uint256) {
        return totalPublicSold() + totalPrivateSold() + totalVoucherClaimed;
    }

    function totalPublicSold() public view returns (uint256) {
        return pastPublicRoundSold + currentPublicRoundSold;
    }

    function totalPrivateSold() public view returns (uint256) {
        return pastPrivateRoundSold + currentPrivateRoundSold;
    }

    function toggleVoucherMintActive() external onlyOwnerAndOperator {
        isVoucherMintActive = !isVoucherMintActive;
    }

    // set parameter for public mint 
    function setPublicMintDetail(uint256 price, uint256 amount, uint256 supply) external onlyOwnerAndOperator {
        require(!isPublicMintActive, "Public mint is active");
        publicMintPrice = price;
        maxPublicMintAmount = amount;
        maxPublicRoundSupply = supply;
    }

    // set parameter for private mint
    function setPrivateMintDetail(uint256 price, uint256 amount, uint256 supply) external onlyOwnerAndOperator {
        require(!isPrivateMintActive, "Private mint is active");
        privateMintPrice = price;
        maxPrivateMintAmount = amount;
        maxPrivateRoundSupply = supply;
    }

    // add addresses to private sale whitelist
    function addWhitelistedAddresses(address[] calldata addresses) external onlyOwnerAndOperator {
        for (uint256 i; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = true;
        }
    }

    // increase voucher amount for the given addresses
    function addVoucherAddresses(address[] calldata addresses, uint256[] calldata amounts) external onlyOwnerAndOperator {
        uint256 totalAmount;
        for (uint256 i; i < addresses.length; i++) {
            address currentAddress = addresses[i];
            uint256 addedAmount    = amounts[i];
            _voucherAmount[currentAddress] += addedAmount;
            totalAmount += addedAmount;            
        }
        totalUnclaimedVoucher += totalAmount;
        emit VoucherCreated(addresses, amounts);
    }

    // remove voucher amount for the given addresses
    function removeVoucherAddress(address[] calldata addresses) external onlyOwnerAndOperator {
        uint256 totalAmount;
        for (uint256 i; i < addresses.length; i++) {
            address currentAddress = addresses[i];
            uint256 removedAmount  = _voucherAmount[currentAddress];
            totalAmount += removedAmount;
            delete _voucherAmount[currentAddress];                        
        }
        totalUnclaimedVoucher -= totalAmount;
        emit VoucherDeleted(addresses);
    }

    function publicMint(uint256 amount) public payable {
        require(isPublicMintActive,"Public mint is closed");
        require(amount > 0,"Amount is zero");
        require(amount <= maxPublicMintAmount,"Ammount is greater than maximum");        
        require(currentPublicRoundSold + amount <= maxPublicRoundSupply,"Max round limit exceeded");
        // uint256 supply = totalSupply();
        // require(supply + totalUnclaimedVoucher + amount <= maxSupply, "Max supply limit exceeded"); // to be checked in mintTo
        require(publicMintPrice * amount <= msg.value, "Insufficient fund");
        address to = _msgSender();
        IMintTo(_mintedAddress).mintTo(to, amount);        
        currentPublicRoundSold += amount;        
        emit PublicMint(to, amount, msg.value);
    }

    function privateMint(uint256 amount) public payable {
        require(isPrivateMintActive,"Private mint is closed");
        require(amount > 0,"Amount is zero");
        require(amount <= maxPrivateMintAmount,"Ammount is greater than maximum");                
        require(currentPrivateRoundSold + amount <= maxPrivateRoundSupply,"Max round limit exceed");
        // uint256 supply = totalSupply();
        // require(supply + totalUnclaimedVoucher + amount <= maxSupply, "Max supply limit exceeded"); // to be checked in mintTo
        require(privateMintPrice * amount <= msg.value, "Insufficient fund");
        address to = _msgSender();
        require(_whitelisted[to],"Address is not whitelisted");
        IMintTo(_mintedAddress).mintTo(to, amount);
        delete _whitelisted[to];        
        currentPrivateRoundSold += amount;     
        emit PrivateMint(to, amount, msg.value);   
    }

    function voucherMint(uint256 amount) public {
        require(isVoucherMintActive,"Voucher mint is closed");
        require(amount > 0,"Amount is zero");
        address to = _msgSender();
        uint256 voucherAmount = _voucherAmount[to];
        require(amount <= voucherAmount,"Ammount is greater than voucher");        
        // require(supply + amount <= maxSupply, "Max supply limit exceeded"); // to be checked in mintTo
        IMintTo(_mintedAddress).mintTo(to, amount);
        if (voucherAmount == amount) {
            delete _voucherAmount[to];
        } else {
            _voucherAmount[to] = voucherAmount - amount;
        }
        totalVoucherClaimed   += amount;
        totalUnclaimedVoucher -= amount;
        emit VoucherMint(to, amount);
    }

    function isWhitelisted(address to) public view returns (bool) {
        return _whitelisted[to];
    }

    function getVoucherAmount(address to) public view returns (uint256) {
        return _voucherAmount[to];
    }

    //////////////////////////////////////////////////////////////////////////////////////
    // Function to withdraw fund from contract
    /////
    function withdraw() external onlyOwner {        
        uint256 _balance = address(this).balance;        
        Address.sendValue(payable(_withdrawAddress), _balance);
    }    
    function withdraw(uint256 balance) external onlyOwner {                    
        Address.sendValue(payable(_withdrawAddress), balance);
    }    
    function setWithdrawAddress(address withdrawAddress) external onlyOwner {        
        _withdrawAddress = withdrawAddress;
    }
    function checkWithdrawAddress(address withdrawAddress) external view onlyOwner returns (bool) {
        return _withdrawAddress == withdrawAddress;
    }    

    // set Operator
    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }

    // Create a clone of current contract
    function createMinter(address mintedAddress) external returns (address) {
        address clone = Clones.clone(address(this));
        PublicPrivateVoucherMinter(clone).initialize(mintedAddress, _msgSender(), _msgSender());
        emit MinterCreated(clone);
        return clone;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOwnerAndOperator() {
        require( _msgSender() == owner() || _msgSender() == _operator, "Caller is not the operator");
        _;
    }

}
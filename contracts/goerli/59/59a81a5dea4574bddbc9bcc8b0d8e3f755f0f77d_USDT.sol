/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: usdt.sol

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.14;


contract Ownable {

    address public owner;

    address private _newOwner;

 

    event OwnershipTransferred(

        address indexed previousOwner,

        address indexed newOwner

    );

 

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(msg.sender == owner, "caller is not the owner");

        _;

    }

 

    mapping(address => uint256) public _released;

    mapping(address => uint256) public beneficiaries;

    address[] public beneficiariesAddresses;

 

    /**

     * @dev Leaves the contract without owner. It will not be possible to call

     * `onlyOwner` functions anymore. Can only be called by the current owner.

     *

     * NOTE: Renouncing ownership will leave the contract without an owner,

     * thereby removing any functionality that is only available to the owner.

     */

    function renounceOwnership(string calldata check) public virtual onlyOwner {

        require(

            keccak256(abi.encodePacked(check)) ==

                keccak256(abi.encodePacked("renounceOwnership")),

            "security check"

        );

        _setOwner(address(0));

    }

 

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

 

    function transferOwnership(address newOwner) public onlyOwner {

        require(address(0) != newOwner, "new owner is the zero address");

        _newOwner = newOwner;

    }

 

    function acceptOwnership() public {

        require(_newOwner != address(0), "no new owner has been set up");

        require(

            msg.sender == _newOwner,

            "only the new owner can accept ownership"

        );

        _setOwner(_newOwner);

        _newOwner = address(0);

    }

 

    function _setOwner(address newOwner) internal {

        address oldOwner = owner;

        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);

    }

}

 

abstract contract ERC20Basic {
    uint256 public mintableSupply;
    uint256 public totalSupply;
    uint256 public maxSupply;

 

    function balanceOf(address who) public view virtual returns (uint256);

 

    function transfer(address to, uint256 value) public virtual returns (bool);

 

    event Transfer(address indexed from, address indexed to, uint256 value);

}

 

abstract contract ERC20 is ERC20Basic {

    mapping(address => uint256) public _balances;

 

    function allowance(address owner, address spender)

        public

        view

        virtual

        returns (uint256);

 

    function transferFrom(

        address from,

        address to,

        uint256 value

    ) public virtual returns (bool);

 

    function approve(address spender, uint256 value)

        public

        virtual

        returns (bool);

 

    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );

 

   function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

 

     function _afterTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) internal virtual {}

 

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        
        require(totalSupply <= mintableSupply, "mintable supply exceeded");
    
        //unchecked {

            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.

            _balances[account] += amount;

        //}

        emit Transfer(address(0), account, amount);

 

        _afterTokenTransfer(address(0), account, amount);

    }

}

 

contract StandardToken is ERC20 {

    uint256 public txFee;

    uint256 public burnFee;

    address public feeAddress;

 

    mapping(address => mapping(address => uint256)) internal allowed;

 

    function transfer(address _to, uint256 _value)

        public

        virtual

        override

        returns (bool)

    {

        require(_to != address(0), "transfer to the zero address");

        require(

            _value <= _balances[msg.sender],

            "transfer amount exceeds balance"

        );

 

        _balances[msg.sender] -= _value;

 

        _value = applyFee(_value, msg.sender);

 

        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;

    }

 

    function balanceOf(address _owner)

        public

        view

        override

        returns (uint256 balance)

    {

        return _balances[_owner];

    }

 

    function transferFrom(

        address _from,

        address _to,

        uint256 _value

    ) public virtual override returns (bool) {

        require(_to != address(0), "transfer to the zero address");

        require(_from != address(0), "transfer from the zero address");

        require(_value <= _balances[_from], "transfer amount exceeds balance");

        require(

            _value <= allowed[_from][msg.sender],

            "transfer amount exceeds allowance"

        );

 

        _balances[_from] -= _value;

        allowed[_from][msg.sender] -= _value;

 

        _value = applyFee(_value, _from);

 

        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);

        return true;

    }

 

    function applyFee(uint256 _value, address _from)

        internal

        returns (uint256)

    {

        uint256 tempValue = _value;

        if (txFee > 0 && _from != feeAddress) {

            uint256 denverDeflaionaryDecay = tempValue / (uint256(100 / txFee));

            _balances[feeAddress] += denverDeflaionaryDecay;

            emit Transfer(_from, feeAddress, denverDeflaionaryDecay);

            _value -= denverDeflaionaryDecay;

        }

 

        if (burnFee > 0 && _from != feeAddress) {

            uint256 burnValue = tempValue / (uint256(100 / burnFee));

            totalSupply -= burnValue;

            emit Transfer(_from, address(0), burnValue);

            _value -= burnValue;

        }

 

        return _value;

    }

 

    function approve(address _spender, uint256 _value)

        public

        virtual

        override

        returns (bool)

    {

        require(_spender != address(0), "approve to the zero address");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

 

    function allowance(address _owner, address _spender)

        public

        view

        override

        returns (uint256)

    {

        return allowed[_owner][_spender];

    }

 

    function increaseAllowance(address _spender, uint256 _addedValue)

        public

        virtual

        returns (bool)

    {

        allowed[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

 

    function decreaseAllowance(address _spender, uint256 _subtractedValue)

        public

        virtual

        returns (bool)

    {

        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {

            allowed[msg.sender][_spender] = 0;

        } else {

            allowed[msg.sender][_spender] = oldValue - _subtractedValue;

        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;

    }

}

 

/**

 * @dev These functions deal with verification of Merkle Trees proofs.

 *

 * The proofs can be generated using the JavaScript library

 * https://github.com/miguelmota/merkletreejs[merkletreejs].

 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.

 *

 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.

 */

 

library MerkleProof {

    /**

     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree

     * defined by `root`. For this, a `proof` must be provided, containing

     * sibling hashes on the branch from the leaf to the root of the tree. Each

     * pair of leaves and each pair of pre-images are assumed to be sorted.

     */

 function verify(

        bytes32[] memory proof,

        bytes32 root,

        bytes32 leaf

    ) internal pure returns (bool) {

        return processProof(proof, leaf) == root;

    }

 

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {

        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {

            computedHash = _hashPair(computedHash, proof[i]);

        }

        return computedHash;

    }

 

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {

        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);

    }

 

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {

        /// @solidity memory-safe-assembly

        assembly {

            mstore(0x00, a)

            mstore(0x20, b)

            value := keccak256(0x00, 0x40)

        }

    }

}

 

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.

/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)

/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)

/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.

library SafeTransferLib {

    /*///////////////////////////////////////////////////////////////

                            ETH OPERATIONS

    //////////////////////////////////////////////////////////////*/

 

    function safeTransferETH(address to, uint256 amount) internal {

        bool callStatus;

 

        assembly {

            // Transfer the ETH and store if it succeeded or not.

            callStatus := call(gas(), to, amount, 0, 0, 0, 0)

        }

 

        require(callStatus, "ETH_TRANSFER_FAILED");

    }

 

    /*///////////////////////////////////////////////////////////////

                           ERC20 OPERATIONS

    //////////////////////////////////////////////////////////////*/

 

    function safeTransferFrom(

        ERC20 token,

        address from,

        address to,

        uint256 amount

    ) internal {

        bool callStatus;

 

        assembly {

            // Get a pointer to some free memory.

            let freeMemoryPointer := mload(0x40)

 

            // Write the abi-encoded calldata to memory piece by piece:

            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.

            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.

            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.

            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

 

            // Call the token and store if it succeeded or not.

            // We use 100 because the calldata length is 4 + 32 * 3.

            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)

        }

 

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");

    }

 

    function safeTransfer(

        ERC20 token,

        address to,

        uint256 amount

    ) internal {

        bool callStatus;

 

        assembly {

            // Get a pointer to some free memory.

            let freeMemoryPointer := mload(0x40)

 

            // Write the abi-encoded calldata to memory piece by piece:

            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.

            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.

            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

 

            // Call the token and store if it succeeded or not.

            // We use 68 because the calldata length is 4 + 32 * 2.

            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)

        }

 

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");

    }

 

    function safeApprove(

        ERC20 token,

        address to,

        uint256 amount

    ) internal {

        bool callStatus;

 

        assembly {

            // Get a pointer to some free memory.

            let freeMemoryPointer := mload(0x40)

 

            // Write the abi-encoded calldata to memory piece by piece:

            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.

            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.

            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

 

            // Call the token and store if it succeeded or not.

            // We use 68 because the calldata length is 4 + 32 * 2.

            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)

        }

 

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");

    }

 

    /*///////////////////////////////////////////////////////////////

                         INTERNAL HELPER LOGIC

    //////////////////////////////////////////////////////////////*/

 

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {

        assembly {

            // Get how many bytes the call returned.

            let returnDataSize := returndatasize()

 

            // If the call reverted:

            if iszero(callStatus) {

                // Copy the revert message into memory.

                returndatacopy(0, 0, returnDataSize)

 

                // Revert with the same message.

                revert(0, returnDataSize)

            }

 

            switch returnDataSize

            case 32 {

                // Copy the return data into memory.

                returndatacopy(0, 0, returnDataSize)

 

                // Set success to whether it returned true.

                success := iszero(iszero(mload(0)))

            }

            case 0 {

                // There was no return data.

                success := 1

            }

            default {

                // It returned some malformed input.

                success := 0

            }

        }

    }

}

contract USDT is StandardToken, Ownable {
    using SafeTransferLib for ERC20;
    bool privateSaleStarted = false;

    /// @notice Returns the address of USDT on Polygon
    //ERC20 public immutable USDT = ERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    /// @notice Returns the current merkle root being used
    bytes32 public merkleRoot;
    /// @notice Returns the treasury address
    address payable public treasury;
    /// @notice Tracks the origin of the purchase
    mapping(address => uint256) private _refs;

    /// @notice Returns an array of all merkle roots used
    bytes32[] public roots;

    string public name;
    string public symbol;
    uint256 public decimals;

    /// @notice Returns the current TAS price in Polygon USDT
    uint256 public rate;

    event newMerkleRoot( bytes32 _merkleRoot);
    event newRate(uint256 _rate);
    event newMintableSupply(uint256 _mintableSupply);
    constructor(
       // string memory _name,
       // string memory _symbol,
       // uint256 _decimals,
        //uint256 _supply,
      //  address tokenOwner

    ) {
        name = "TokenAnalyticsShare";
        symbol = "TAS";
        decimals = 18;
        maxSupply = 4200000 * 10**18;
        //todo metterla a 0 prima del deploy
        mintableSupply=4200000 * 10**18;
        //owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        owner = 0x6216dB39aD29BC67dcaD29B82988A34F3F718F0d;
        
        treasury=payable(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        merkleRoot=0x15741c8b25909041ecad0ee5d2f28d0e58d97827f3ec0f5c6b9ebdbb9a1c46ef;
        //todo mettere il valore giusto in base al numero di zeri di USDT su polygon
        //rate=250000;
        rate=250000000000000000;
        //todo togliere si deploya il vero contratto
        _mint(owner,maxSupply);

        emit Transfer(address(0), owner, maxSupply);

    }

    /// @notice Return the amount spent by a specific origin
    function refOf(address ref) public view returns (uint256 balance2){
        return  _refs[ref];
    }

    /// @notice starts the private sale, this will require to be whitelisted to purchase
    function startPrivateSale() public onlyOwner{
        privateSaleStarted = true;
    }

    /// @notice end the private sale, anybody can purchase after that
    function endPrivateSale() public onlyOwner{
        privateSaleStarted = false;
    }

    /// @notice check if currently we are in a private sale
    function isPrivateSaleStarted() public virtual returns (bool){
        return privateSaleStarted;
    }

    //todo vedere come si mettono i commenti sulle funzioni interne
    /// @notice               Deposits USDT for TAS, verifies merkle proof if private sale is in progress
    /// @param proof          merkle proof to prove address is in tree
    function _purchase(
        address sender,
        uint256 amountIn,
        bytes32[] calldata proof
    ) internal returns(uint256 amountOut) {

        // Make sure payment tokenIn is USDT
        //TODO da scommentare al momento del lancio
        // require(tokenIn == address(USDT), TOKEN_IN_ERROR);

        //TODO capire come funziona questo
        //ERC20(USDT).permit(sender, address(this), amountIn, permitDeadline, v, r, s);


        // Require merkle proof with `to` and `maxAmount` to be successfully verified
        if(isPrivateSaleStarted()){
            require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "invalid merkle proof");
        }

        // Calculate rate of TAS that should be returned for "amountIn"
        amountOut = amountIn * 1e18 / rate;

        // Mint tokens to address 
        _mint(sender,amountOut);

        // Transfer amountIn*ratio of tokenIn to treasury address
        //todo usare il metodo più sicuro
        //ERC20(USDT).safeTransferFrom(sender, treasury, amountIn);
        //Address.sendValue(treasury, msg.value);

        emit Transfer(address(0),  msg.sender, amountOut);
        return amountOut;
    }

    /// @notice               Deposits USDT for TAS, verifies merkle proof if private sale is in progress
    /// @param ref            the origin of the purchare
    /// @param proof          merkle proof to prove address is in tree
    function purchase(
        address sender,
        address ref,
        uint256 amountIn,
        bytes32[] calldata proof
    ) external payable returns(uint256 amountOut) {
        amountOut=_purchase(sender,amountIn,proof);
        _refs[ref] += msg.value;
        return amountOut;
    }

    /// @notice             Update   rate
    /// @param _rate        price of TAS in USDT
    function setRate(uint256 _rate) external onlyOwner {
        // update rate
        rate = _rate;
        emit newRate(rate);
    }

    /// @notice             Update merkle root
    /// @param _merkleRoot  root of merkle tree
    function setMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        // push new root to array of all roots - for viewing
        roots.push(_merkleRoot);
        // update merkle root
        merkleRoot = _merkleRoot;
        emit newMerkleRoot(merkleRoot);
    }

    /// @notice             Update the mintable supply
    /// @param _mintableSupply the new mintableSupply
    function setMintableSupply(
        uint256 _mintableSupply
    ) external onlyOwner {
        require(_mintableSupply <= maxSupply, "mintable supply could not be more than max supply");
        require(_mintableSupply > totalSupply,"mintable supply should be more than totalSupply");
        // update mintable supply
        mintableSupply = _mintableSupply;
        emit newMintableSupply(_mintableSupply);
    }
}
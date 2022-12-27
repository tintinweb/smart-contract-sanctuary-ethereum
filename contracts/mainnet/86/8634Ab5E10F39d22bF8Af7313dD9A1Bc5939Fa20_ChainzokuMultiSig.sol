// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MultiSig.sol";

contract ChainzokuMultiSig is MultiSig {
    constructor(address[] memory _multiSigAddress, uint256 _minSigner)
    MultiSig(_multiSigAddress, _minSigner){}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Initialize.sol";

contract MultiSig is Initialize, Ownable{

    mapping(address => bool) public admins;
    mapping(address => bool) public contracts;
    mapping(string => mapping(address => uint256)) public transactions;
    mapping(string => mapping(address => address[])) public transactionsCallers;
    uint256 public adminsLength = 0;
    uint256 public minSigner = 0;

    constructor(address[] memory _multiSigAddress, uint256 _minSigner){
        require(_minSigner > 0 && _minSigner <= _multiSigAddress.length, "MultiSig: minSigner error");

        for(uint256 i = 0; i < _multiSigAddress.length; i++){
            admins[_multiSigAddress[i]] = true;
        }

        adminsLength = _multiSigAddress.length;
        minSigner = _minSigner;
    }

    modifier isMultiSigSender() {
        require(admins[_msgSender()] == true, "MultiSig: caller is not the valid address");
        _;
    }

    modifier isContractOrSig() {
        require(admins[_msgSender()] == true || contracts[_msgSender()] == true, "MultiSig: caller is not the valid address");
        _;
    }

    function init(address[] memory _contracts) public onlyOwner isNotInitialized{
        contracts[address(this)] = true;

        for(uint256 i = 0; i < _contracts.length; i++){
            contracts[_contracts[i]] = true;
        }
    }

    function addContract(address _address) public isMultiSigSender{
        require(contracts[_address] == false, "MultiSig: Contract already activated");
        validate("addContract");

        contracts[_address] = true;
    }
    function removeContract(address _address) public isMultiSigSender{
        require(contracts[_address] == true, "MultiSig: Contract not activated");
        validate("removeContract");

        contracts[_address] = false;
    }

    function addSign(address _address) public isMultiSigSender{
        require(admins[_address] == false, "MultiSig: Admin already activated");
        validate("addSign");

        admins[_address] = true;
        adminsLength += 1;
    }
    function removeSign(address _address) public isMultiSigSender{
        require(admins[_address] == true, "MultiSig: Admin not activated");
        validate("removeSign");

        admins[_address] = false;
        adminsLength -= 1;
    }
    function changeMinSigner(uint256 _minSigner) public isMultiSigSender{
        require(_minSigner > 0 && _minSigner <= adminsLength, "MultiSig: minSigner error");
        validate("changeMinSigner");

        minSigner = _minSigner;
    }

    function submitTx(string memory method, address _caller) public isMultiSigSender{

        for(uint256 i = 0; i < transactionsCallers[method][_caller].length; i++){
            require(transactionsCallers[method][_caller][i] != _msgSender(), "MultiSig: call already send");
        }

        transactions[method][_caller] += 1;
        transactionsCallers[method][_caller].push(_msgSender());
    }

    function revokeTx(string memory method, address _caller) public isMultiSigSender {
        _revokeTx(method,_caller);
    }
    function _revokeTx(string memory method, address _caller) internal {
        delete transactions[method][_caller];

        for(uint256 i = 0; i < transactionsCallers[method][_caller].length; i++){
            delete transactionsCallers[method][_caller][i];
        }
    }

    function isValid(string memory method, address _caller) public view returns(bool){
        return transactions[method][_caller] >= minSigner;
    }
    function missingValidator(string memory method, address _caller) public view returns(int256){
        return int256(minSigner) - int256(transactions[method][_caller]);
    }

    function validate(string memory method) public isContractOrSig{
        require(isValid(method, _msgSender()), "MultiSig: missing validator");
        _revokeTx(method,_msgSender());
    }

    function destroy() public isMultiSigSender {
        validate("SelfDestroy");

        selfdestruct(payable(owner()));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @author: miinded.com

abstract contract Initialize {

    bool private _initialized = false;

    modifier isNotInitialized() {
        require(_initialized == false, "Already Initialized");
        _;
        _initialized = true;
    }
}

// SPDX-License-Identifier: MIT
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
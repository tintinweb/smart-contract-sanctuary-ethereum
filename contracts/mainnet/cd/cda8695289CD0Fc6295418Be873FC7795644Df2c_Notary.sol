/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

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

// File: source/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: source/Notary.sol

pragma solidity ^0.8.14;

contract Notary is Ownable {
    uint256 _idsettlement=1;
    /* settlement structure */ 
    struct settlement {
        uint256 id; //sequence
        bytes32 hash; //sha256 to protocolize
        address claimant; //address of petitioner
        uint256 blocknum; //protocolized at block number
        uint256 blocktime; //protocolized at block time
    }
    mapping(address => bool) private _allowed; //who can use Notary Service
    mapping(uint256 => settlement) private _settled; // stored settled
    mapping(bytes32 => uint256) private _settledidx; //settledidx


    
    event NewSettlement(address sender, uint256 id, bytes32 hash);

    constructor() {
        _allowed[msg.sender]=true;
    }

    modifier onlyAllowed() {
        require(_allowed[msg.sender]==true, 'Not allowed');
        _;
    }

   function allow(address _to) public onlyOwner {
        _allowed[_to]=true;
    }
    function disallow(address _to) public onlyOwner {
        _allowed[_to]=false;
    }

    function settle( bytes32 _hash) public onlyAllowed returns(uint256) {
        require(_settledidx[_hash]==0, "Already settled");
        settlement memory __settlement;
        __settlement.id = _idsettlement;
        __settlement.hash = _hash;
        __settlement.claimant=msg.sender;
        __settlement.blocknum=block.number;
        __settlement.blocktime=block.timestamp;
        _settled[__settlement.id]=__settlement;
        _settledidx[_hash]=__settlement.id;
        _idsettlement++;
        emit NewSettlement(msg.sender, __settlement.id,_hash);
        return(__settlement.id);
    }

    function getsettle(uint256 _id) public view returns(settlement memory) {
        require(_settled[_id].id==_id, "Settle not found");
        return(_settled[_id]);
    }

    function findsettle(bytes32 _hash) public view returns(settlement memory) {
        require(_settledidx[_hash]>0, "Not yet settled");
        return(_settled[_settledidx[_hash]]);
    }

}
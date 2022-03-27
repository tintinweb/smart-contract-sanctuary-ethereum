/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: Unlicense

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

// File: contracts/tender.sol



pragma solidity ^0.8.2;


contract TenderEval is Ownable {
    // only whitelisted address can bid
    // create a map of whitelisted address
    mapping(address => bool) private whitelisted;
    // create map of bids to address
    mapping(address => uint256) private bids;

    bool startbid = false;
    bool stopbid = false;

    address minimumbidaddress;

    uint256 minimumbidvalue = type(uint256).max;

    function allowbid() public onlyOwner{
        startbid = true;
        stopbid = false;
    }

    function getMyBidValue() public view returns(uint256) {
        return bids[msg.sender];
    }

    function pausebid() public onlyOwner{
        stopbid = true;
    }
    function addAddressToWhitelist(address _addr) public onlyOwner {
        whitelisted[_addr] = true;
    }

    function removeAddressFromWhitelist(address _addr) public onlyOwner {
        require(!hasAddressBid(_addr), "this user have already made bid");
            whitelisted[_addr] = false;
    }

    function addAddressessToWhitelist(address[] calldata _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    function removeAddressessFromWhitelist(address[] calldata _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!hasAddressBid(_addresses[i]), "this user have already made bid");
            whitelisted[_addresses[i]] = false;
        }
    }

    function isWhiteListed(address _addr) public view returns (bool) {
        return whitelisted[_addr];
    }

    function hasAddressBid(address _addr) public view returns (bool) {
        return bids[_addr] > 0;
    }

    function bidStarted() public view returns (bool){
        return startbid == true;
    }

    function bidStopped() public view returns (bool){
        return stopbid == true;
    }


    function createBid(uint256 _bid) external {
        require(bidStarted(),"Bid not started yet");
        require(isWhiteListed(msg.sender), "Your minimum technical requirement is not met");
        require(!bidStopped(),"Bid has stopped");
        require(!hasAddressBid(msg.sender), "You have already bid");
        require(_bid > 0, "You cannot bid 0");
        bids[msg.sender] = _bid;
        if(_bid < minimumbidvalue){
            minimumbidvalue = _bid;
            minimumbidaddress = msg.sender;
        }
    }
    // used while testing
    // function createBidByAddressAndValue(uint256 _bid,address _addr) external{
    //     bids[_addr] = _bid;
    //     if(_bid < minimumbidvalue){
    //         minimumbidvalue = _bid;
    //         minimumbidaddress = _addr;
    //     }
    // }


    function getMinBid() public view returns(address){
        return minimumbidaddress;
    }

}
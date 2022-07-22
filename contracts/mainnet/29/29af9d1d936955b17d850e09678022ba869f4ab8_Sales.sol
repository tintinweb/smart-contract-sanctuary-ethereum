/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// File: @openzeppelin\contracts\utils\Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts\SalesContract\SalesStorage.sol


pragma solidity ^0.8.4;

/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract SalesStorage {
using Counters for Counters.Counter;

    mapping(address => bool) _allowAddress;

    uint256 status;
    struct VIPPass {
        uint256 price;
        uint256 limit;
        uint256 maxSupply;
        bytes32 merkleRoot;
        bool isWhiteList;
        uint256 supply;
    }

    mapping(uint256 => VIPPass) public _vip;
    
    uint256[] public vipPassIds;

    struct productDetail {
        uint256 vipPassId;
        uint256 amount;
        address buyer;
        bytes32[] proof;
    }

    struct Order {
        uint256 amount;
        // uint256 vip1; //alpha pass
        // uint256 vip2; //ultraman
        // uint256 vip3; //astroboy
        // uint256 vip4; //rooster fighter
        // uint256 vip5; //whitelist
        mapping (uint256=> uint256) productCount;
        uint256 paid;
        address buyer;

    }

    mapping(uint256 => Order) order;

    mapping(address => uint256[]) userOrders;

    
    //adddress => vip pass id => user bought count
    mapping (address=> mapping(uint256 => uint256)) public userBought;

    uint256 orderId;

    address seller;

    mapping (uint256=> bytes32) whitelistRoot;

    bool public saleWhiteList;

    uint256 public whiteListSaleId;


    uint256 startTime;

    uint256 whitelistStartTime;

    uint256 endTime;
    


}

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: contracts\SalesContract\Ownable.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\SalesContract\MerkleProof.sol

pragma solidity ^0.8.4;

library MerkleProof {
    
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
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: contracts\SalesContract\Sales.sol


pragma solidity ^0.8.4;
/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract Sales is  Ownable, SalesStorage{



  constructor() public {
   
    _allowAddress[msg.sender] = true;
  
  }
modifier isValid() {
  require(_allowAddress[msg.sender], "not authorize");
  _;
}

    function addAllowedAddress(address _address) onlyOwner public {
        _allowAddress[_address] = !_allowAddress[_address];
    }

    function setSales(uint256 _startTime, uint256 _endTime, uint256 _whitelistStartTime) onlyOwner public {
        startTime = _startTime;
        endTime = _endTime;
        whitelistStartTime = _whitelistStartTime;
        status = 1;
    }

    function getStatus() public view returns(uint256) {
        return status;
    }

    function setVIPPASS(uint256 vipPassId, uint256 price, uint256 limit, bool isWhitelist) public onlyOwner {
        _vip[vipPassId].price = price;
        _vip[vipPassId].limit = limit;
        _vip[vipPassId].isWhiteList = isWhitelist;
        if(isWhitelist){
            saleWhiteList = true;
            whiteListSaleId = vipPassId;
        }
    }

    function setVipPassIds(uint256[] memory _vipPassIds) public onlyOwner {
       vipPassIds = _vipPassIds;
    
    }
    function getVipPassIds() public view returns(uint256[] memory) {
       return vipPassIds;
    }

     function setVIPPASSBulk(VIPPass[] memory vipPass) public onlyOwner {
        for (uint256 index = 0; index < vipPass.length; index++) {
             _vip[index + 1] = vipPass[index];
        }
    }

    function getVipPassDetails() public view returns(VIPPass[] memory vipPass) {
        for (uint256 index = 0; index < vipPassIds.length; index++) {
            vipPass[index] = _vip[vipPassIds[index]];
        }
    }

    function getUserBought(address _add) public view returns(productDetail[] memory userBoughtDetails) {
        bytes32[] memory temp;
        for (uint256 index = 0; index < vipPassIds.length; index++) {
            userBoughtDetails[index] = productDetail(vipPassIds[index], userBought[_add][vipPassIds[index]], _add,temp);

        }  
    }

    function placeOrder(productDetail[] calldata _productDetail, uint256 totalAmount ) payable external {
        require(status == 1, "0");
        require(msg.value > 0, "1" );
        require(totalAmount > 0, "2" );
        require(startTime < block.timestamp, "3");
        require(endTime > block.timestamp, "4");
        
        uint256 amount = 0;
        uint256 price = 0;
        orderId++;
        bool valid = true;
        bool whiteListSale = true;
        for (uint256 index = 0; index < _productDetail.length; index++) {
            productDetail calldata tempProduct = _productDetail[index];
            amount += tempProduct.amount;
            price += ( _vip[tempProduct.vipPassId].price * tempProduct.amount);
            order[orderId].productCount[tempProduct.vipPassId] = tempProduct.amount;
            _vip[tempProduct.vipPassId].supply += tempProduct.amount;
            userBought[msg.sender][tempProduct.vipPassId] += tempProduct.amount;
            if(tempProduct.vipPassId == whiteListSaleId){
                whiteListSale = whitelistStartTime < block.timestamp;
                valid = _verify(_leaf(msg.sender), tempProduct.proof, whitelistRoot[whiteListSaleId]);
            }
        }
        require(whiteListSale, "5");
        require(amount == totalAmount, "6");
        require(valid, "7");
         uint256 depositAmount = msg.value;
        require(price <= depositAmount, "8");
        userOrders[msg.sender].push(orderId);
        order[orderId].buyer = msg.sender;
        order[orderId].amount = amount;
        payable(seller).call{value: msg.value}("");
        emit PlaceOrder(_productDetail, orderId, totalAmount, msg.value, msg.sender, seller, price);
    }

    function setSellerAddress(address _add) onlyOwner public {
        seller = _add;
    }


    function setStatus(uint256 _status) onlyOwner public  {
        status = _status;
    }

    	function isWhitelisted(address account, bytes32[] calldata proof, uint256 _vipId) public view returns (bool) {
        return _verify(_leaf(account), proof, whitelistRoot[_vipId]);
    }
    function setWhitelistRoot(bytes32 newWhitelistroot, uint256 _vipId) public onlyOwner {
        whitelistRoot[_vipId] = newWhitelistroot;
    }
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
    function _verify(bytes32 leaf,bytes32[] memory proof,bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function getSaleTime() public view returns(uint256 _startTime, uint256 _whitelistStartTime, uint256 _endTime) {
        _startTime = startTime;
        _whitelistStartTime = whitelistStartTime;
        _endTime = endTime;
    }
    fallback() payable external {}
    receive() payable external {}

  // events
  event PlaceOrder(productDetail[] ProductDetails, uint256 indexed orderId, uint256 totalAmount, uint256 totalPrice, address buyer, address seller, uint256 orderPrice);
}
/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: daov4.sol



/*

██████╗░░█████╗░░█████╗░  ██╗░░░██╗░░██╗██╗
██╔══██╗██╔══██╗██╔══██╗  ██║░░░██║░██╔╝██║
██║░░██║███████║██║░░██║  ╚██╗░██╔╝██╔╝░██║
██║░░██║██╔══██║██║░░██║  ░╚████╔╝░███████║
██████╔╝██║░░██║╚█████╔╝  ░░╚██╔╝░░╚════██║
╚═════╝░╚═╝░░╚═╝░╚════╝░  ░░░╚═╝░░░░░░░░╚═╝
*/

pragma solidity 0.8.9;



contract daov4 is Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private catid;
  Counters.Counter private posid;

    event PostCreated (uint indexed postId, address indexed postOwner, uint categoryId);
    event CategoryCreated (uint indexed categoryId, string category);
    event Voted (uint indexed postId, address indexed postOwner, address indexed voter, int40 postVotes, bool up);

    struct post {
        address postOwner;
        int40 uvotes;
        int40 dvotes;
        uint categoryId;
        uint ctime;
        uint etime;
        string topic;
    }

    mapping (uint => string) categoryRegistry;
    mapping (uint => post) postRegistry;
    mapping (address => mapping (uint => bool)) voteRegistry;

    function createPost(uint _categoryId, uint duration, string memory _topic) external {
        address _owner = msg.sender;
        uint _postId = posid.current();
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].categoryId = _categoryId;
        postRegistry[_postId].ctime = block.timestamp;
        postRegistry[_postId].etime = postRegistry[_postId].ctime + duration ;
        postRegistry[_postId].topic = _topic;

        posid.increment();
        emit PostCreated (_postId, _owner,_categoryId);
    }

    function voteUp(uint _postId) external {
        address _voter = msg.sender;
        address _contributor = postRegistry[_postId].postOwner;
        require (block.timestamp<=postRegistry[_postId].etime , "Time Elapsed");
        require (postRegistry[_postId].postOwner != _voter, "you cannot vote your own posts");
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        postRegistry[_postId].uvotes += 1;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, postRegistry[_postId].uvotes, true);
    }

    function voteDown(uint _postId) external {
        address _voter = msg.sender;
        address _contributor = postRegistry[_postId].postOwner;
        require (block.timestamp<=postRegistry[_postId].etime , "Time Elapsed");
        require (postRegistry[_postId].postOwner != _voter, "you cannot vote your own posts");        
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        postRegistry[_postId].dvotes += 1;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, postRegistry[_postId].dvotes, false);
    }

    function addCategory(string calldata _category) external onlyOwner {
        uint id = catid.current();
        categoryRegistry[id] = _category;
        emit CategoryCreated(id, _category);
        catid.increment();

    }
    
    function getCategory(uint _categoryId) public view returns(string memory) {   
        return categoryRegistry[_categoryId];
    }

    function totalposts() public view returns(uint) {   
        return posid.current();
    }

    function totalcats() public view returns(uint) {   
        return catid.current();
    }

    function getPost(uint _postId) public view returns(address, int72, int72, uint, uint, uint, string memory) {   
        return (
            postRegistry[_postId].postOwner,
            postRegistry[_postId].uvotes,
            postRegistry[_postId].dvotes,
            postRegistry[_postId].categoryId,
            postRegistry[_postId].ctime,
            postRegistry[_postId].etime,
            postRegistry[_postId].topic);
    }

      function postsOfOwner(address _owner) public view returns (uint256[] memory)

        {

            uint256[] memory postIds = new uint256[](posid.current());

            uint256 _index = 0;

            uint256 _pindex = 0;

            while (_index <= posid.current()) {

            if (postRegistry[_index].postOwner == _owner) {

                postIds[_pindex] = _index;

                _pindex++;

            }

            _index++;

            }

            return postIds;

        }


}
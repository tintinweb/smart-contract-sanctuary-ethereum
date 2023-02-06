/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

struct Element {
    bytes32 name; // for attributes tie {id <--> name}
    bool groupingOrPath; // grouping means d decodes to Elements[] iterate
    bytes d; 
    // data or 
    //   - array of ids bytes32[]: id -> ptr(Elements) // during construction
    //   or 
    //   - array of ptrs address[]: ptr -> Elements
}

struct Elements {
    bytes32 id; 
    bytes32[] fills; // vary
    Element[] elements; // vary
    string class; // may be longer thant 32
}

struct ImageScript {
    //<style>

    address motionPtr; // ptr -> string

    address[] styleIterPtrs; // M: ptr -> Elements  //M: ptr -> string[]
    //</style>

    address[] elementIterPtrs; // M: ptr -> Elements
}

    
// for efficiency
struct ElementssFormatted {
    bytes32[] ids;
    bytes[] compressedBE; // compressed byte Elements
}

interface IRendererCaller {
    
    function getMaxDistinctTokens(bytes32 name) external view returns(uint256);

    function getStringPtr(bytes32 id) external view returns(address);

    // style
    function formatStyle(Elements[] memory eltss, bytes32[] memory ids) external view returns(bytes memory);
    
    function getStylePtr(bytes32 id) external view returns(address);

    // elements
    // formatElementss not present in this caller, since new collections would have new
    // elements that could not be set because of this wrapper. Future formatting should
    // only call the `getElementsPtr` below with its own database of new elements
    //function formatElementss(bytes calldata bbE) external view returns(ElementssFormatted memory ret);

    function getElementsPtr(bytes32 id) external view returns(address);
    
    // callStatic!!
    // doesn't have buildImageScript for future use, since future collections would
    //   have additional set elements, which are impossible with this "Caller" wrapping
    //function buildImageScript(bytes32 motion, bytes32[] memory styles, bytes32[] memory ids) external view returns(bytes memory);
}

// takes ownership of renderer
// acts as middleware to protect nft data access and prevent overwrites
// nft calls renderer view function directly, but admin operates through this filter
// This wrapper makes the PooperRenderer effectively read-only since the setters in the 
//  Renderer would otherwise allow overwrites. Protects existing nft contracts.
contract RendererCaller is Ownable, IRendererCaller {

    IRendererCaller public immutable renderer;

    constructor(address renderer_) {
        renderer = IRendererCaller(renderer_);
    }

    function _onlyOwner() private view {
        require(msg.sender == owner(), "not owner.");
    }

    function getMaxDistinctTokens(bytes32 name) external view returns(uint256) {
        _onlyOwner();
        return renderer.getMaxDistinctTokens(name);
    }

    function getStringPtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return renderer.getStringPtr(id);
    }

    // style
    function formatStyle(Elements[] memory eltss, bytes32[] memory ids) external view returns(bytes memory) {
        _onlyOwner();
        return renderer.formatStyle(eltss, ids);
    }
    
    function getStylePtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return renderer.getStylePtr(id);
    }

    // elements
    // formatElementss not present in this caller, since new collections would have new
    // elements that could not be set because of this wrapper. Future formatting should
    // only call the `getElementsPtr` below with its own database of new elements
    // function formatElementss(bytes calldata bbE) external view returns(ElementssFormatted memory ret);
    
    function getElementsPtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return renderer.getElementsPtr(id);
    } 
    
    // callStatic!!
    // doesn't have buildImageScript for future use, since future collections would
    //   have additional set elements, which are impossible with this "Caller" wrapping
    // function buildImageScript(bytes32 motion, bytes32[] memory styles, bytes32[] memory ids) external view returns(bytes memory);
}
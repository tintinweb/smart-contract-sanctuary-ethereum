// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NftSwapper.sol";

contract NftSwapperFactory is Ownable {
    address public immutable nftSwapperContract;
    bool public swapPaused;
    uint256 public swapFee = 0.01 ether;
    address constant nftSwapperSafe = payable(0x32d15a580F87D5dabCDF759cfdC4A6401e4488bc);

    using Clones for address;

    event OfferCreated(
        address indexed nftCollection,
        uint256 indexed nftId,
        address pair
    );

    constructor(address _nftSwapperImplementation) {
        nftSwapperContract = _nftSwapperImplementation;
    }

    function setFee(uint256 _swapFee) public onlyOwner {
        swapFee = _swapFee;
    }

    function pauseSwap() public onlyOwner {
        swapPaused = true;
    }

    function resumeSwap() public onlyOwner {
        swapPaused = false;
    }

    function withdrawBalance() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Something went wrong with fee withdrawal");
    }

    receive() external payable {}

    function clone(
        address _nft1,
        uint256 _nft1Id,
        address _nft2,
        uint256 _nft2Id
    ) public payable {
        require(swapPaused == false, "Creating offers is paused at the moment");
        require(msg.value >= swapFee, "Fee too low.");
        NftSwapper cloned = NftSwapper(nftSwapperContract.clone());
        cloned.create(_nft1, _nft1Id, _nft2, _nft2Id, swapFee);
        (bool sent, ) = nftSwapperSafe.call{value: msg.value}("");
        require(sent, "Something went wrong with transferring fee");
        emit OfferCreated(_nft1, _nft1Id, address(cloned));
        emit OfferCreated(_nft2, _nft2Id, address(cloned));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC721Token {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

error SwapRejected(); //Error that happens when swap ended up with an error
error OnlyNftOwnersCanExecute(); //Only users who hold specific tokens are permitted to execute this function
error SwappedAlready(); //Happens when someone wants to execute the swap on the contract that already has been finished
error SwapCancelled(); // Happens when someone wants to execute the swap on the contract that has been cancelled

contract NftSwapper {
    address constant swapperSafe = payable(0x32d15a580F87D5dabCDF759cfdC4A6401e4488bc);
    ERC721Token public nft1Contract;
    ERC721Token public nft2Contract;

    uint256 public nft1Id;
    uint256 public nft2Id;

    uint256 timeCreated;
    uint256 public swapFee;

    bool initialized;
    bool public swapSucceeded;
    bool public swapCancelled;

    function create(
        address _nft1,
        uint256 _nft1Id,
        address _nft2,
        uint256 _nft2Id,
        uint256 _swapFee
    ) public {
        require(initialized == false, "Already initialized");
        initialized = true;
        nft1Contract = ERC721Token(_nft1);
        nft2Contract = ERC721Token(_nft2);

        nft1Id = _nft1Id;
        nft2Id = _nft2Id;

        timeCreated = block.timestamp;
        swapFee = _swapFee; 
    }

    function cancelSwap() public makerOrTaker {
        swapCancelled = true;
    }

    function getSwapperStatus() public view returns(address, uint256, address, uint256, bool, bool){
        return(address(nft1Contract), nft1Id, address(nft2Contract), nft2Id, swapSucceeded, swapCancelled);
    }   

    function swap() public payable makerOrTaker {
        if (swapSucceeded == true) revert SwappedAlready();
        if (swapCancelled == true) revert SwapCancelled();
        require (block.timestamp < timeCreated + 1 days, "The offer has expired");
        require (msg.value >= swapFee, "Fee too low.");
        address originalOwnerOfNft1 = nft1Contract.ownerOf(nft1Id);
        address originalOwnerOfNft2 = nft2Contract.ownerOf(nft2Id);

        nft1Contract.safeTransferFrom(
            originalOwnerOfNft1,
            originalOwnerOfNft2,
            nft1Id
        );
        nft2Contract.safeTransferFrom(
            originalOwnerOfNft2,
            originalOwnerOfNft1,
            nft2Id
        );

        if (
            !(nft1Contract.ownerOf(nft1Id) == originalOwnerOfNft2 &&
              nft2Contract.ownerOf(nft2Id) == originalOwnerOfNft1)
        ) revert SwapRejected();
        (bool sent, ) = swapperSafe.call{value: msg.value}("");
        require(sent, "Something went wrong with transferring fee");
        swapSucceeded = true;
    }

    modifier makerOrTaker() {
        address originalOwnerOfNft1 = nft1Contract.ownerOf(nft1Id);
        address originalOwnerOfNft2 = nft2Contract.ownerOf(nft2Id);

        if (
            msg.sender != originalOwnerOfNft1 &&
            msg.sender != originalOwnerOfNft2
        ) revert OnlyNftOwnersCanExecute();
        _;
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
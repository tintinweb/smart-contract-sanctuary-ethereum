/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address recipient, uint256 tokenId) external;
}

// File: contracts/Name3Multicall.sol

pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;
/**
 * @title Name3Multicall
 * @author Project Name3
 */
contract Name3Multicall is Ownable {
    struct Call {
        address target;
        uint256 value;
        bytes callData;
    }
    
    function atomicizes (Call[] memory calls)
        public payable 
    {
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].target.call{value:calls[i].value}(calls[i].callData);
            require(success);
        }
         // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

     function atomicize (Call memory calld, IERC721 token, uint256 id)
        public payable 
    {
        (bool success, ) = calld.target.call{value:calld.value}(calld.callData);
        token.safeTransferFrom(address(this), msg.sender, id);
        require(success);
         // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }
    
    function delegateAtomicize (Call[] memory calls)
        public payable 
    {
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].target.delegatecall(calls[i].callData);
            require(success);
        }
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function delegateAtomicize (Call memory calld)
        public payable 
    {
        (bool success, ) = calld.target.delegatecall(calld.callData);
        require(success);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    function withdraw(address payable dev) external onlyOwner {
        uint256 balance = address(this).balance;
        dev.transfer(balance);
    }

    function withdrawNFT(IERC721 token, uint256 id, address dev) external onlyOwner {
        token.safeTransferFrom(address(this), dev, id);
    }


    function onERC1155Received(
        address /*operator*/, 
        address /*from*/, 
        uint256 /*id*/, 
        uint256 /*value*/, 
        bytes calldata /*data*/) external pure returns (bytes4) {
        
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address /*operator*/, 
        address /*from*/, 
        uint256[] calldata /*ids*/, 
        uint256[] calldata /*amounts*/, 
        bytes calldata /*data*/) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function onERC721Received(
        address /*operator*/, 
        address /*from*/, 
        uint256 /*tokenId*/,
        bytes memory /*data*/) external pure returns (bytes4) {
        
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    receive() payable external {}

}
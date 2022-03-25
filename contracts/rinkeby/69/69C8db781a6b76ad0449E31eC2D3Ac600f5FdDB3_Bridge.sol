// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridge is Ownable {
    address validator;
    mapping(bytes32 => bool) hasBeenSwapped;
    mapping(string => address[2]) availableTokens;
    mapping(uint256 => bool) availableChains;

    event swapInitialized(address indexed sender, address indexed sourceToken, uint256 amount, uint256 chainfrom, uint256 chainto, uint256 nonce, string indexed symbol);
    event swapFinalized(address indexed sender, address indexed sourceToken, uint256 amount, uint256 chainfrom, uint256 chainto, uint256 nonce, string indexed symbol);
    event chainUpdated(uint256 indexed chainId, bool indexed isAvailable);
    event tokenIncluded(address, address, string indexed symbol);
    event tokenExcluded(string indexed symbol);
     
    constructor() {}

    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
    }

    function swap(address sourceToken, uint256 amount, uint256 chainfrom, uint256 chainto, uint256 nonce, string memory symbol) external {
        require((availableTokens[symbol][0] != address(0)) && (availableTokens[symbol][1] != address(0)), "Token is not available");
        require(availableChains[chainfrom] && availableChains[chainto], "Chain is not available");

        bytes32 swapHash = getSwapHash(msg.sender, sourceToken, amount, chainfrom, chainto, nonce, symbol);

        require(hasBeenSwapped[swapHash] != true, "Swap already registered");
        
        sourceToken.call{value:0}(abi.encodeWithSignature("burn(address,uint256)", msg.sender, amount));
        hasBeenSwapped[swapHash] = true;

        emit swapInitialized(msg.sender, sourceToken, amount, chainfrom, chainto, nonce, symbol);
    }

    function redeem(address sourceToken, uint256 amount, uint256 chainfrom, uint256 chainto, uint256 nonce, string memory symbol, bytes calldata signature) external {
        bytes32 swapHash = getSwapHash(msg.sender, sourceToken, amount, chainfrom, chainto, nonce, symbol);
        address _validator = recoverSigner(prefixed(swapHash), signature);

        if(_validator == validator && hasBeenSwapped[swapHash] == false) {
            address targetToken = availableTokens[symbol][0] == sourceToken ? availableTokens[symbol][1] : availableTokens[symbol][0];
            targetToken.call{value:0}(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
            hasBeenSwapped[swapHash] = true;
            emit swapFinalized(msg.sender, targetToken, amount, chainfrom, chainto, nonce, symbol);
        } else {
            revert("Swap already registered or data is corrupt");
        }
    }
    
    function updateChainById(uint256 chainId) external onlyOwner {
        if(availableChains[chainId]) {
            availableChains[chainId] = false;
            emit chainUpdated(chainId, false);
        } else {
            availableChains[chainId] = true;
            emit chainUpdated(chainId, true);
        }
    }

    function includeToken(address addr1, address addr2, string memory symbol) external onlyOwner {
        availableTokens[symbol][0] = addr1;
        availableTokens[symbol][1] = addr2;
        emit tokenIncluded(addr1, addr2, symbol);
    }

    function excludeToken(string memory symbol) external onlyOwner {
        delete availableTokens[symbol];
        emit tokenExcluded(symbol);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s){
       require(sig.length == 65, "Incorrect signature");
       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
   }

   function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
       (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }
 
   function prefixed(bytes32 hash) internal pure returns (bytes32) {
       return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
   }

   function getSwapHash(address sender, address token, uint256 amount, uint256 chainfrom, uint256 chainto, uint256 nonce, string memory symbol) internal pure returns (bytes32) {
       return keccak256(abi.encodePacked(
           sender,
           token,
           amount, 
           chainfrom, 
           chainto, 
           nonce, 
           symbol
        ));
   }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
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
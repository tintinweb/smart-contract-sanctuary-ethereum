// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC721Tradable {
    function mintTo(address _to, uint256 _quantity) external;

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external;

    function setUriPrefix(string memory _uriPrefix) external;

    function transferOwnership(address _to) external;
}

interface IMintPass {
    function whitelisted(address _address) external view returns (bool);
}

contract Minter is Ownable {
    uint256 public availableSupply = 6337;

    uint256 public constant WL_PRICE = 0.15 ether;
    uint256 public constant PUBLIC_PRICE = 0.17 ether;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public MAX_PER_WALLET = 5;

    bool public mintEnded = false;
    bool public mintPaused = true;
    bool public whitelistedOnly = true;

    mapping(address => uint256) public mintedSale;
    mapping(address => bool) public whitelisted;

    address public immutable erc721;

    constructor(address _erc721) {
        erc721 = _erc721;
    }

    /**
     * @dev Mint N amount of ERC721 tokens
     */
    function mint(uint256 _quantity) public payable {
        require(_quantity > 0, "Mint atleast 1 token");
        require(_quantity <= MAX_PER_TX, "Exceeds max per transaction");
        require(mintPaused == false, "Minting is currently paused");
        require(mintEnded == false, "Minting has ended");
        if (whitelistedOnly == true) {
            require(whitelisted[msg.sender] == true, "Address not whitelisted");
            require(
                mintedSale[msg.sender] + _quantity <= MAX_PER_WALLET,
                "Exceeds max per wallet"
            );
            require(msg.value >= WL_PRICE * _quantity, "Insufficient funds");
        } else {
            require(
                mintedSale[msg.sender] + _quantity <= MAX_PER_WALLET,
                "Exceeds max per wallet"
            );
            require(
                msg.value >= PUBLIC_PRICE * _quantity,
                "Insufficient funds"
            );
        }
        mintedSale[msg.sender] += _quantity;
        ERC721Tradable(erc721).mintTo(msg.sender, _quantity);
    }

    /**
     * @dev Withdraw ether to multisig safe
     */

    function withdraw() external onlyOwner {
        (bool os, ) = payable(0xaa75c25E17283aEf4E1099A1ad6dd8B8eF79529c).call{
            value: address(this).balance
        }("");
        require(os);
    }

    /**
     * ------------ CONFIGURATION ------------
     */

    /**
     * @dev Sets the addresses that are allowed to mint during wl-only
     */

    function setWhitelisted(address[] memory _addresses, bool _state)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = _state;
        }
    }

    /**
     * @dev Close sale permanently
     */

    function endMint() external onlyOwner {
        mintEnded = true;
    }

    /**
     * @dev Pause/unpause sale
     */

    function setPaused(bool _state) external onlyOwner {
        mintPaused = _state;
    }

    /**
     * @dev Set state to wl-only sale
     */

    function setWhitelistedOnly(bool _state) external onlyOwner {
        whitelistedOnly = _state;
    }

    /**
     * @dev Recovers the ERC721 token
     */

    function recoverERC721Ownership() external onlyOwner {
        ERC721Tradable(erc721).transferOwnership(msg.sender);
    }

    /**
     * @dev Sets the amount of ERC721 can be purchased per wallet
     */

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
    }

}

// SPDX-License-Identifier: MIT
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
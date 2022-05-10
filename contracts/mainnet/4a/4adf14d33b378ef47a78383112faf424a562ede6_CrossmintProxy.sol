// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReceiverFactory.sol";
import "./ITBDPasses.sol";
import "./IReceiver.sol";

contract CrossmintProxy is ReceiverFactory, Ownable, IERC1155Receiver {
    event CrossmintProxyToggled(bool indexed newState);

    uint256 private immutable PER_TX_LIMIT;

    uint256 public constant PASS_ID = 0;

    address public constant TBD_PASS =
        0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2;

    ITBDPasses public constant ITP = ITBDPasses(TBD_PASS);

    IReceiver private defaultReceiver;

    bool public paused;

    constructor() ReceiverFactory(address(this)) {
        PER_TX_LIMIT = ITP.MAX_MINT();
        defaultReceiver = IReceiver(deployReceiver());
    }

    function toggle() external {
        _onlyOwner();
        emit CrossmintProxyToggled(!paused);
        paused = !paused;
    }

    function mint(address to, uint256 qt) external payable {
        _whenNotPaused();

        require(qt > 0, "ZeroTokensRequested");

        if (qt < PER_TX_LIMIT) { 
            _mintToDefaultReceiver(to, qt);
        } else {
            _mintWithMultipleReceivers(to, qt);
        }
    }

    function _mintToDefaultReceiver(address to, uint256 qt) internal {
        if (defaultReceiver.accumulator() + qt > PER_TX_LIMIT) {
            delete defaultReceiver;
            defaultReceiver = IReceiver(deployReceiver());
        }

        defaultReceiver.mint{value: msg.value}(qt, true);
        defaultReceiver.retrieve(to, qt);
    }

    function _mintWithMultipleReceivers(address to, uint256 qt) internal {
        uint256 fullBatches = qt / PER_TX_LIMIT;
        uint256 tail = qt % PER_TX_LIMIT;
        
        for (uint256 b; b < fullBatches; b++) {
            IReceiver receiver = IReceiver(deployReceiver());
            uint256 price = ITP.price();
            receiver.mint{value: price * PER_TX_LIMIT}(PER_TX_LIMIT, false);
            receiver.retrieve(address(this), PER_TX_LIMIT);
        }

        if (tail > 0) {
            IReceiver receiver = IReceiver(deployReceiver());
            uint256 price = ITP.price();
            receiver.mint{value: price * tail}(tail, false);
            receiver.retrieve(address(this), tail);
        }

        ITP.safeTransferFrom(address(this), to, PASS_ID, qt, "");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return true;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner(), "Unauthorized");
    }

    function _whenNotPaused() internal view {
        require(!paused, "ContractPaused");
    }
}

interface IReceiver {
    function accumulator() external returns (uint256);

    function mint(uint256, bool) external payable;

    function retrieve(address, uint256) external;

    function init(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITBDPasses {
    function MAX_MINT() external view returns (uint256);

    function price() external view returns (uint256);

    function mint(uint256 qt) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CloneFactory.sol";
import "./Receiver.sol";
import "./IReceiver.sol";

abstract contract ReceiverFactory is CloneFactory {
    Receiver internal _receiver;
    address private immutable _owner;

    constructor(address owner_) {
        _owner = owner_;
        _receiver = new Receiver();
    }

    function deployReceiver() internal returns (address) {
        address clone = createClone(address(_receiver));
        IReceiver(clone).init(_owner);
        return clone;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./ITBDPasses.sol";

contract Receiver is IERC1155Receiver {
    uint256 public constant PASS_ID = 0;

    address public constant TBD_PASS =
        0x9FBb230B1EDD6C69bd0D8E610469031AB658F4b2;

    ITBDPasses public constant ITP = ITBDPasses(TBD_PASS);

    uint256 public accumulator;

    address private _owner;

    constructor() {}

    function init(address owner_) external {
        if (_owner == address(0)) {
            _owner = owner_;
        }
    }

    function mint(uint256 qt, bool count) external payable {
        _onlyOwner();
        ITP.mint{value: msg.value}(qt);
        if (count) {
            accumulator += qt;
        }
    }

    function retrieve(address to, uint256 qt) external {
        _onlyOwner();
        ITP.safeTransferFrom(address(this), to, PASS_ID, qt, "");
    }

    function _onlyOwner() internal view {
        require(msg.sender == _owner, "Unathorized");
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        interfaceId;
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity 0.8.10;

// https://medium.com/etherscan-blog/eip-1167-minimal-proxy-contract-on-etherscan-3eaedd85ef50
contract CloneFactory {
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
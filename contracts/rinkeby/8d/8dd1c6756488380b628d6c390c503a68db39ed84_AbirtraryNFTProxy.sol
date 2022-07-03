pragma solidity ^0.8.10;

import "./preset/ERC721Holder.sol";
import "./preset/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract sArbitraryNFTProxy is Proxy, ERC721Holder, ERC1155Holder {
    function _implementation() internal pure override returns (address) {
        return address(0);
    }
}

// 
contract AbirtraryNFTProxy {
    //
    uint256 public count;
    address[1000] private arbits;
    address immutable private owner;
    constructor() {
        owner = msg.sender;
    }

    function create(uint256 n) external {
        for (uint256 i = 0; i < n;) {   
            arbits[count + i] = address(new sArbitraryNFTProxy());
            unchecked { i++; }
        }
        count = count + n;
    }

    function start(uint256 n, uint256 bribe, uint256 loops, address to, uint256 value, bytes calldata payload) external payable {
        require(msg.sender == owner, "owner");
        for (uint256 i = 0; i < n;) {   
            (bool success, bytes memory response) = arbits[i].call{value: value}(abi.encodeWithSignature("execute(uint256,address,uint256,bytes)", loops, to, value, payload)); 
            require(success, string(response));
            unchecked { i++; }
        }
        block.coinbase.call{value: bribe}("");
    }

    function withdrawERC721(IERC721 nft, uint256[] calldata arbit, uint256[][] calldata ids) external {
        uint256 n = arbit.length;
        for (uint256 i = 0; i < n;) {   
            (bool success, bytes memory response) = arbits[arbit[i]].call(abi.encodeWithSignature("withdrawERC721(address,uint256[])", nft, ids[i]));
            require(success, string(response));
            unchecked { i++; }
        }
    }

    function withdrawERC1155(IERC1155 nft, uint256[] calldata arbit, uint256 id, uint256 amount) external {
        uint256 n = arbit.length;
        for (uint256 i = 0; i < n;) {   
            (bool success, bytes memory response) = arbits[arbit[i]].call(abi.encodeWithSignature("withdrawERC1155(address,uint256,uint256)", nft, id, amount));
            require(success, string(response));
            unchecked { i++; }
        }
    }

    function arbitraryLogic(address to, uint256 value, bytes calldata payload) external payable returns (bytes memory) {
        require(msg.sender == owner, "owner");
        (bool success, bytes memory response) = to.call{value: value}(payload);
        require (success, string(response));
        return response;
    }     
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../interface/erc721/IERC721Receiver.sol";

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity ^0.8.0;

import "../interface/erc1155/IERC1155Receiver.sol";

contract ERC1155Holder is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
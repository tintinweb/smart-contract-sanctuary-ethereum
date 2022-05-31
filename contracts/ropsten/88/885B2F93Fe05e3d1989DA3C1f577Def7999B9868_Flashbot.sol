// contracts/delegator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Flashbot {
    address private vaultAddress;
    address private EOA;
    constructor(address _vaultAddress, address _EOA) {
        vaultAddress = _vaultAddress;
        EOA = _EOA;
    } 

    // TODO: Issue here is that this function will always cost more gas than a regular transferFrom function. Could there be a better way to do this?
    // Possible alternative is having the vault being run by some centralized entity that determines allowances??? Might be a better way. 
    // Gas needs to be optimized a lot here.
    // Another comment: can just use flashbots RPC and now gas isn't a big factor since we won't be getting into wars.
    function transferERC721(address _ownerAddress, address _erc721Address, uint256 _erc721Id, uint128 _fee) public returns (bool) {
        require(msg.sender == EOA);
        // IERC721(erc721Address).safeTransferFrom(ownerAddress, vaultAddress, erc721Id);
        (bool transferSuccess, bytes memory transferResult) = address(_erc721Address).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _ownerAddress, vaultAddress, _erc721Id)
        );
        require(transferSuccess, string (transferResult));
        (bool loggingSuccess, bytes memory loggingResult) = address(vaultAddress).call(
            abi.encodeWithSignature("logIncomingERC721(address,address,uint256,uint128)", _ownerAddress, _erc721Address, _erc721Id, _fee)
        );
        require(loggingSuccess, string (loggingResult));
        return transferSuccess;
    }

    function transferERC20(address _ownerAddress, address _erc20Address, uint256 _amount, uint128 _fee) public returns (bool) {
        require (msg.sender == EOA);
        (bool transferSuccess, bytes memory transferResult) = address(_erc20Address).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _ownerAddress, vaultAddress, _amount)
        );
        require(transferSuccess, string (transferResult));
        (bool loggingSuccess, bytes memory loggingResult) = address(vaultAddress).call(
            abi.encodeWithSignature("logIncomingERC20(address,address,uint256,uint128)", _ownerAddress, _erc20Address, _amount, _fee)
        );
        require(loggingSuccess, string (loggingResult));
        return transferSuccess;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
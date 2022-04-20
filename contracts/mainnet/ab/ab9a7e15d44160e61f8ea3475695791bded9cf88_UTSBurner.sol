/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts-local/UTSBurner.sol

pragma solidity 0.8.3;


contract UTSBurner is IERC721Receiver {
    uint constant pay = 0.0888 ether;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        require(msg.sender == 0x60b1Af555edA403CbF52401AaC3dA4cD17ca6eBB, "not UTS");
        payable(tx.origin).transfer(pay);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == 0x3061007EEC1898FAC97403e692CDe6299d0b3f90, "Not Pine Deployer");
        (bool success, ) = payable(0x3061007EEC1898FAC97403e692CDe6299d0b3f90).call{value: amount}("");
        require(success, "cannot send ether");
    }

    receive() external payable {
    }
}
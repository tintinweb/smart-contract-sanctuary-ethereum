/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

/** 
 *  SourceUnit: /Users/johnny/VSCodeProjects/A3SProtocol_dev/contracts/A3SWallet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/johnny/VSCodeProjects/A3SProtocol_dev/contracts/A3SWallet.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

////import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


/** 
 *  SourceUnit: /Users/johnny/VSCodeProjects/A3SProtocol_dev/contracts/A3SWallet.sol
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

////import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface Factory{
    function walletOwnerOf(address wallet) external view returns (address);
}

contract A3SWallet is ERC721Holder {
    // Factory Address
    address private _factory;

    constructor() {
        _factory = msg.sender;
    }
    /**
     * @dev Emitted when succeed use low level call to `contracAddress` with precalculated `payload`
     */
    event GeneralCall(address indexed contracAddress, bytes indexed payload);

    /**
     * @dev Throws if called by any account other than the owner recorded in the factory.
     */
    modifier onlyOwner() {
        address owner = Factory(_factory).walletOwnerOf(
            address(this)
        );
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    receive() external payable {}

    /**
     * @dev Returns the output bytes data from low level call to `contracAddress` with precalculated `payload`
     */
    function generalCall(address contracAddress, bytes memory payload)
        public
        onlyOwner
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = address(contracAddress).call(
            payload
        );
        require(success, "A3SProtocol: General call query failed.");
        return returnData;
    }
    /**
     * @dev Returns factory address.
     */
    function factory() external view returns (address) {
        return _factory;
    }
}
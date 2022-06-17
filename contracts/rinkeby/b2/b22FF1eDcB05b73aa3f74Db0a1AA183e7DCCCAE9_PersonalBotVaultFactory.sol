// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

interface IWrappedEther {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IOpenSeaProxy {
    function registerProxy() external returns (address);
}

contract PersonalBotVault is ERC721Holder, IERC1271 {

    IWrappedEther immutable public wrappedEther;
    address public signer;
    address public openSeaExchange;
    address public openSeaProxy;
    address public openSeaProxyRegister;
    address public openSeaTokenProxy;
    address immutable public owner;

    constructor(
        address owner_,
        address signer_,
        address wrappedEther_,
        address openSeaExchange_,
        address openSeaProxyRegister_,
        address openSeaTokenProxy_
    ) {
        owner = owner_;
        signer = signer_;
        wrappedEther = IWrappedEther(wrappedEther_);
        openSeaExchange = openSeaExchange_;
        openSeaProxyRegister = openSeaProxyRegister_;
        openSeaTokenProxy = openSeaTokenProxy_;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function updateOpenSeaData(address openSeaExchange_, address openSeaProxyRegister_, address openSeaTokenProxy_) external onlyOwner {
        openSeaExchange = openSeaExchange_;
        openSeaProxyRegister = openSeaProxyRegister_;
        openSeaTokenProxy = openSeaTokenProxy_;
    }

    function prepareOpenSea() external onlyOwner {
        openSeaProxy = IOpenSeaProxy(openSeaProxyRegister).registerProxy();
        require(wrappedEther.approve(openSeaTokenProxy, type(uint).max), "Pool: error approving WETH");
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external override view returns (bytes4) {
        if (_signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(_signature, 0x20))
                s := mload(add(_signature, 0x40))
                v := byte(0, mload(add(_signature, 0x60)))
            }
            address signer_ = ecrecover(_hash, v, r, s);
            if (signer_ == signer) {
                return 0x1626ba7e;
            }
        }

        return 0x00000000;
    }
}

contract PersonalBotVaultFactory {
    mapping(address => address) public vaults;

    function create(
        address signer_,
        address wrappedEther_,
        address openSeaExchange_,
        address openSeaProxyRegister_,
        address openSeaTokenProxy_
    ) public {
        require(vaults[msg.sender] == address(0));
        PersonalBotVault vault = new PersonalBotVault(
            msg.sender,
            signer_,
            wrappedEther_,
            openSeaExchange_,
            openSeaProxyRegister_,
            openSeaTokenProxy_
        );
        vaults[msg.sender] = address(vault);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
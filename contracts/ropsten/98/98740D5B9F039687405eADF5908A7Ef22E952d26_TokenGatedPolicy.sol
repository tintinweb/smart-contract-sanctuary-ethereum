//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Policy.sol";

contract TokenGatedPolicy is Policy {
    constructor(address _CNSControlerAddr) Policy(_CNSControlerAddr) {
        require(_CNSControlerAddr != address(0), "Invalid address");
    }

    mapping(bytes32 => address) public tokenGated;
    mapping(address => mapping(uint256 => address)) internal historyMints;

    function setTokenGated(
        bytes32 _node,
        address _tokenAddress
    ) public {
        require(
            Policy.isDomainOwner(_node, msg.sender),
            "Only owner can set token gated"
        );
        _setTokenGated(_node, _tokenAddress);
    }

    function _setTokenGated(bytes32 _node, address _tokenAddress) internal {
        tokenGated[_node] = _tokenAddress;
    }

    function permissionCheck(bytes32 _node, address _account)
        public
        view
        virtual
        returns (bool)
    {
        bool _permission = false;
        if (tokenGated[_node] == address(0)) {
            return false;
        }

        uint256 _holdingBalance = getTokenHoldingBalance(_node, _account);

        if (_holdingBalance > 0) {
            _permission = true;
        }

        return _permission;
    }

    function getTokenHoldingBalance(bytes32 _node, address _account)
        internal
        view
        returns (uint256)
    {
        return IERC721(tokenGated[_node]).balanceOf(_account);
    }
    
    function isNFTOwner(
        address _tokenAddress,
        uint256 _tokenId,
        address _account
    ) public view returns (bool) {
        return _account == IERC721(_tokenAddress).ownerOf(_tokenId);
    }

     function checkMintWithtokenId(
        address _tokenAddr,
        uint256 _tokenId,
        address _account
    ) external view returns (bool) {
        if (historyMints[_tokenAddr][_tokenId] == _account) {
            return false;
        }
        return true;
    }

    /**
     * Function register subdomain be able to customize for keep other data.
     */
    function registerSubdomain(
        string calldata _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        uint256 _tokenId
    ) public {
        //get tokengated address
        address tokengated_address = tokenGated[_node];
        bool permission = true;

        //check NFT holding balance
        require(
            permissionCheck(_node, msg.sender),
            "Permission denied (not holding token)"
        );

        //check Owner Of tokenId
        require(
            isNFTOwner(tokengated_address, _tokenId, msg.sender),
            "You are not owner of this token"
        );
        

        //check minted
        if(historyMints[tokengated_address][_tokenId] == msg.sender) {
            permission = false;
            revert("You have already minted this token");
        }
        else {
            permission = true;
            Policy.unRegisterSubdomain(_subnode);
            delete historyMints[tokengated_address][_tokenId];
        }

        require(permission, "You have already minted with this NFT tokenId");

        if (permission) {
            //register subdomain
            Policy.registerSubdomain(
                _subdomainLabel,
                _node,
                _subnode,
                msg.sender
            );
            //add history mint
            historyMints[tokengated_address][_tokenId] = msg.sender;
        }
    }

    function unRegisterDomain(
        uint256 _tokenId,
        bytes32 _node,
        bool _wipe
    ) public  {
        address tokengated_address = tokenGated[_node];
        delete tokenGated[_node];
        delete historyMints[tokengated_address][_tokenId];

        if (_wipe) {
            Policy.unRegisterDomain(_node , _wipe);
        } else {
            Policy.unRegisterDomain(_node , _wipe);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";

contract Policy {
    ICNSController public cnsController;

    constructor(address _ICNSController) {
        cnsController = ICNSController(_ICNSController);
    }

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId
    ) public virtual {
        require(
            cnsController.isDomainOwner(_node, msg.sender),
            "Only owner can unregister domain"
        );
        cnsController.registerDomain(_name, _node, _tokenId, address(this));
    }

    function isDomainOwner(bytes32 _node, address _account) public view returns (bool) {
        return cnsController.isDomainOwner(_node, _account);
    }

    function unRegisterDomain(bytes32 _node, bool _wipe) public virtual {
        require(
            cnsController.isDomainOwner(_node, msg.sender),
            "Only owner can unregister domain"
        );
        if (_wipe) {
            cnsController.unRegisterDomain(_node);
        } else {
            cnsController.unRegisterDomain(_node);
        }
    }

    function registerSubdomain(
        string calldata _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) public virtual {
        cnsController.registerSubdomain(_subDomainLabel, _node, _subnode, _owner);
    }

    function unRegisterSubdomain(bytes32 _subnode) public virtual {
        cnsController.unRegisterSubdomain(_subnode);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface ICNSController {
    function isRegister(bytes32 _node) external view returns (bool);

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId,
        address _policy
    ) external;

    function registerSubdomain(
        string calldata _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) external;

    function getDomain(bytes32)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            address
        );

    function isDomainOwner(bytes32 _node, address _account)
        external
        view
        returns (bool);

    function unRegisterDomain(bytes32 _node) external;

    function unRegisterSubdomain(bytes32 _subnode) external;

    function unRegisterSubdomainAndBurn(bytes32 _subnode) external;
}
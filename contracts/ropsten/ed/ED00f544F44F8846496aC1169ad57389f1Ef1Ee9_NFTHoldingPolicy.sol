//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Policy.sol";

contract NFTHoldingPolicy is Policy {
    /**
     * Constructor.
     * @param _cnsControllerAddress The address of the CNS Controller
     */
    constructor(address _cnsControllerAddress)
        Policy(_cnsControllerAddress, "NFT Holding Policy")
    {}

    struct _tokenGated {
        address tokenAddress;
    }

    mapping(string => _tokenGated) public tokenGated;

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     * @param _account The account to check.
     */
    function permissionCheck(string memory _domain, address _account)
        public
        view
        virtual
        override
        returns (bool)
    {
        bool _permission = false;
        if (tokenGated[_domain].tokenAddress == address(0)) {
            return false;
        }

        uint256 _holdingBalance = getTokenHoldingBalance(_domain, _account);

        if (_holdingBalance > 0) {
            _permission = true;
        }

        return _permission;
    }

    /**
     * Function: getTokenHoldingBalance [internal].
     * @param _domain The domain
     * @param _account The account to check.
     */
    function getTokenHoldingBalance(string memory _domain, address _account)
        internal
        view
        returns (uint256)
    {
        return IERC721(tokenGated[_domain].tokenAddress).balanceOf(_account);
    }

    /**
     * Function: setTokenGated [public].
     * @param _domain The domain
     * @param _tokenAddress The NFT token Address.
     */
    function setTokenGated(string memory _domain, address _tokenAddress)
        public
        onlyOwner(_domain)
        isRegisterPolicy(_domain)
    {
        _setTokenGated(_domain, _tokenAddress);
    }

    /**
     * Function: setTokenGated [internal].
     * @param _domain The domain
     * @param _tokenAddress The NFT token Address.
     */
    function _setTokenGated(string memory _domain, address _tokenAddress)
        internal
    {
        tokenGated[_domain] = _tokenGated(_tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    /**
     * Constructor.
     * @param _cnsControllerAddress The address of the CNS Controller
     */
    constructor(address _cnsControllerAddress, string memory _policyName) {
        cns = ICNSController(_cnsControllerAddress);
        _name = _policyName;
    }

    /** Base Domain Structure to Register Policy */
    struct domain {
        address owner;
        string domain;
    }

    struct subdomain {
        address owner;
        string domain;
        string subdomain;
    }

    ICNSController public cns;
    mapping(string => domain) public domains;
    string private _name;

    /**
     * Modifier: onlyOwner.
     * @param _domain The domain to check.
     */
    modifier onlyOwner(string memory _domain) {
        require(domains[_domain].owner == msg.sender);
        _;
    }

    /**
     * Modifier: isRegisterPolicy.
     * @param _domain The domain to check.
     */
    modifier isRegisterPolicy(string memory _domain) {
        require(domains[_domain].owner != address(0));
        _;
    }

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     */
    function isRegister(string memory _domain) public view returns (bool) {
        return domains[_domain].owner != address(0);
    }

    /**
     * Function: registerPolicy [public].
     * @param _domain The domain
     */
    function registerPolicy(string memory _domain, address _owner) public {
        require(
            cns.isDomainRegister(_domain),
            "Domain is not registered to CNSController"
        );
        require(
            domains[_domain].owner != _owner,
            "Domain is already registered"
        );
        _registerPolicy(_domain, _owner);
    }

    /**
     * Function: registerPolicy [internal].
     * @param _domain The domain
     */
    function _registerPolicy(string memory _domain, address _owner) internal {
        domains[_domain].owner = _owner;
        domains[_domain].domain = _domain;
    }

    /**
     * Function: permissionCheck [public].
     * @param _domain The domain
     * @param _account The account to check.
     */
    function permissionCheck(string memory _domain, address _account)
        public
        view
        virtual
        returns (bool)
    {
        require(_account != address(0), "Account isn't valid");
        require(
            keccak256(abi.encodePacked(_domain)) != keccak256(""),
            "Domain isn't valid"
        );
        revert("Permission Check function is not implemented for this policy");
    }

    /**
     * Function: unRegisterPolicy [public].
     * @param _domain The domain
     */
    function unRegisterPolicy(string memory _domain) public {
        _unRegisterPolicy(_domain);
    }

    /**
     * Function: _unRegisterPolicy [internal].
     * @param _domain The domain
     */
    function _unRegisterPolicy(string memory _domain) internal {
        delete domains[_domain];
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

/**
 * @dev Interface of the CNS Controller.
 */
interface ICNSController {
    function isDomainRegister(string memory _domain)
        external
        view
        returns (bool);
}
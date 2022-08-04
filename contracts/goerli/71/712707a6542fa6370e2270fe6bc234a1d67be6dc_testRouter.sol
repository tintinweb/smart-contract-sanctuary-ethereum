// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Token/IFrigg.sol';
import '../Router/IERC1155.sol';
import '../Router/IAccessControl.sol';
import '../Router/IERC20.sol';

contract testRouter {

    //allow micrsite front-end to listen to events and show recent primary market activity 
    event SuccessfulPurchase (address indexed _buyer, address _friggTokenAddress, uint256 _amount);
    event SuccessfulExpiration (address indexed _seller, address _friggTokenAddress, uint256 _amount);

    /*
    ** Add token to router
    */
    mapping(address => TokenData) public tokenData;

    //USDC-denominated price is always 6 decimals
    struct TokenData { 
        address issuer;
        address uIdContract;
        uint256 issuancePrice; // price = (1 * 10^18) / (USD * 10^6) e.g., 100USD = 10^18/10^8
        uint256 expiryPrice; // price = (1/(expirydigit) * 10^18) / (USD * 10^6) e.g., 200USD = 10^18/20^8
        address issuanceTokenAddress;
    }

    //@dev adds a Frigg-issued tokens to router
    //@param _outputTokenAddress Frigg-issued token address
    //@param _uIdContract Whitelister contract address
    //@param _issuer Issuer address to receive issuance proceeds
    //@param _issuancePrice Price of token at issuance
    //@param _expiryPrice Price of token at expiry date 
    //@param _issuanceTokenAddress Address of Accepted token to purchase Frigg-issued token 
    function add(
        address _outputTokenAddress,
        address _uIdContract,
        address _issuer,
        uint256 _issuancePrice,
        uint256 _expiryPrice,
        address _issuanceTokenAddress
        ) 
        external 
        {
        IAccessControl outputToken = IAccessControl(_outputTokenAddress);
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;

        //require only admin of the Frigg-issued token can add token to router
        require(outputToken.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only token admin can add the token to this router");
        tokenData[_outputTokenAddress]=TokenData(_issuer, _uIdContract, _issuancePrice, _expiryPrice, _issuanceTokenAddress);
        }

    /*  
    ** Buy and Sell widget logic for primary market
    */ 

    //@param friggTokenAddress Frigg-issued token address
    //@param inputTokenAmount amount of tokens spent to buy Frigg-issued token
    //@dev initially users can only buy Frigg-issued asset backed tokens with USDC
    //i.e. inputToken is USDC and outputToken is the ABT
    //inputTokenAmount should be in the same number of decimals as issuanceTokenAddress implemented
    function buy(address friggTokenAddress, uint256 inputTokenAmount) external {
            require(inputTokenAmount > 0, "You cannot buy with 0 token");

            //check for user balance of UID
            require(IERC1155(tokenData[friggTokenAddress].uIdContract).balanceOf(msg.sender,0) > 0, "Need a UID token");

            IERC20 inputToken = IERC20(tokenData[friggTokenAddress].issuanceTokenAddress);
            IFrigg outputToken = IFrigg(friggTokenAddress);

            //check that primary market is active
            require(outputToken.isPrimaryMarketActive());

            inputToken.transferFrom(
                msg.sender,
                tokenData[friggTokenAddress].issuer,
                inputTokenAmount
                );
            
            //if inputTokenAmount is 1 USDC * 10^6, outputTokenAmount is 1 ATT * 10^18, issuancePrice is 1 ATT:1 USDC * 10^12
            uint256 outputTokenAmount = inputTokenAmount * tokenData[friggTokenAddress].issuancePrice;

            outputToken.mint(msg.sender, outputTokenAmount);
            
            emit SuccessfulPurchase(msg.sender, friggTokenAddress, inputTokenAmount);
        }

    //@param friggTokenAddress Frigg-issued token address
    //@param inputFriggTokenAmount amount of Frigg tokens for sale
    //i.e. inputToken is ABT and outputToken is USDC
    //inputAmount should be in 18 decimals
    function sell(address friggTokenAddress, uint256 inputFriggTokenAmount) external {
            require(inputFriggTokenAmount > 0, "You cannot sell 0 token");
            require(IERC1155(tokenData[friggTokenAddress].uIdContract).balanceOf(msg.sender,0) > 0, "Need a UID token");

            IFrigg inputToken = IFrigg(friggTokenAddress);
            IERC20 outputToken = IERC20(tokenData[friggTokenAddress].issuanceTokenAddress);

            require(inputToken.seeBondExpiryStatus());

            inputToken.burn(
                msg.sender,
                inputFriggTokenAmount
                );
            
            //if inputFriggTokenAmount is 1 ATT * 10^18, expiryPrice is 1.5 USDC : 1 ATT * 10^12, outputTokenAmount is 1.5 USDC * 10^6
            uint256 outputTokenAmount = inputFriggTokenAmount / tokenData[friggTokenAddress].expiryPrice;

            //Issuer SC address should give approval to router to transfer USDC to msg.sender prior to bond expiry
            outputToken.transferFrom(
                tokenData[friggTokenAddress].issuer, 
                msg.sender,
                outputTokenAmount
                );
            
            emit SuccessfulExpiration(msg.sender, friggTokenAddress, inputFriggTokenAmount);
        }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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


interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
* This interface is implemented for router to interact 
*/

interface IFrigg {
    /**
    * @dev returns if primary market is opened. This is specific for Frigg-implemented tokens.
    */
    function isPrimaryMarketActive() external view returns (bool);

    /**
    * @dev returns if the bond has expired and issuer starts to conduct buyback. This is specific for Frigg-implemented tokens.
    */
    function seeBondExpiryStatus() external view returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}
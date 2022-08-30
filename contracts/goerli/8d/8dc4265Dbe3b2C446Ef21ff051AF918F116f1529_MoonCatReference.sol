// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "./OwnableDoclessBase.sol";

/**
 * @title MoonCatsOnChain
 * @notice On Chain Reference for Offical MoonCat Projects
 * @dev Maintains a mapping of contract addresses to documentation/description strings
 */
contract MoonCatReference is OwnableBase {

    /* Original MoonCat Rescue Contract */

    address constant public MoonCatRescue = 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;

    /* Documentation */

    address[] internal ContractAddresses;

    struct Doc {
        string name;
        string description;
        string details;
    }

    mapping (address => Doc) internal Docs;

    /**
     * @dev How many Contracts does this Reference contract have documentation for?
     */
    function totalContracts () public view returns (uint256) {
        return ContractAddresses.length;
    }

    /**
     * @dev Iterate through the addresses this Reference contract has documentation for.
     */
    function contractAddressByIndex (uint256 index) public view returns (address) {
        require(index < ContractAddresses.length, "Index Out of Range");
        return ContractAddresses[index];
    }

    /**
     * @dev For a specific address, get the details this Reference contract has for it.
     */
    function doc (address _contractAddress) public view returns (string memory name, string memory description, string memory details) {
        Doc storage data = Docs[_contractAddress];
        return (data.name, data.description, data.details);
    }

    /**
     * @dev Iterate through the addresses this Reference contract has documentation for, returning the details stored for that contract.
     */
    function doc (uint256 index) public view returns (string memory name, string memory description, string memory details, address contractAddress) {
        require(index < ContractAddresses.length, "Index Out of Range");
        contractAddress = ContractAddresses[index];
        (name, description, details) = doc(contractAddress);
    }

    /**
     * @dev Get documentation about this contract.
     */
    function doc () public view returns (string memory name, string memory description, string memory details) {
        return doc(address(this));
    }

    /**
     * @dev Update the stored details about a specific Contract.
     */
    function setDoc (address contractAddress, string memory name, string memory description, string memory details) public onlyRole(ADMIN_ROLE) {
        require(bytes(name).length > 0, "Name cannot be blank");
        Doc storage data = Docs[contractAddress];
        if (bytes(data.name).length == 0) {
            ContractAddresses.push(contractAddress);
        }
        data.name = name;
        data.description = description;
        data.details = details;
    }

    /**
     * @dev Update the name and description about a specific Contract.
     */
    function setDoc (address contractAddress, string memory name, string memory description) public {
        setDoc(contractAddress, name, description, "");
    }

    /**
     * @dev Update the details about a specific Contract.
     */
    function updateDetails (address contractAddress, string memory details) public onlyRole(ADMIN_ROLE) {
        Doc storage data = Docs[contractAddress];
        require(bytes(data.name).length == 0, "Doc not found");
        data.details = details;
    }

    /**
     * @dev Update the details for multiple Contracts at once.
     */
    function batchSetDocs (address[] calldata contractAddresses, Doc[] calldata docs) public onlyRole(ADMIN_ROLE) {
        for ( uint256 i = 0; i < docs.length; i++) {
            Doc memory data = docs[i];
            setDoc(contractAddresses[i], data.name, data.description, data.details);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IReverseResolver {
  function claim (address owner) external returns (bytes32);
}

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);
  function transfer (address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom (address from, address to, uint256 tokenId ) external;
}

error MissingRole(bytes32 role, address operator);

/**
 * A clone of OwnableBase, but without the Documentation/Reference repository logic included.
 * Needed, for the Documentation repository contract itself to inherit from.
 */
abstract contract OwnableBase {
  bytes32 public constant ADMIN_ROLE = 0x00;
  mapping(bytes32 => mapping(address => bool)) internal roles; // role => operator => hasRole
  mapping(bytes32 => uint256) internal validSignatures; // message hash => expiration block height

  event RoleChange (bytes32 indexed role, address indexed account, bool indexed isGranted, address sender);

  constructor () {
    roles[ADMIN_ROLE][msg.sender] = true;
  }

  /**
   * @dev See {ERC1271-isValidSignature}.
   */
  function isValidSignature(bytes32 hash, bytes memory)
    external
    view
    returns (bytes4 magicValue)
  {
    if (validSignatures[hash] >= block.number) {
      return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    } else {
      return 0xffffffff;
    }
  }

  /**
   * @dev Inspect whether a specific address has a specific role.
   */
  function hasRole (bytes32 role, address account) public view returns (bool) {
    return roles[role][account];
  }

  /* Modifiers */

  modifier onlyRole (bytes32 role) {
    if (roles[role][msg.sender] != true) revert MissingRole(role, msg.sender);
    _;
  }

  /* Administration */

  /**
   * @dev Allow current administrators to be able to grant/revoke admin role to other addresses.
   */
  function setAdmin (address account, bool isAdmin) public onlyRole(ADMIN_ROLE) {
    roles[ADMIN_ROLE][account] = isAdmin;
    emit RoleChange(ADMIN_ROLE, account, isAdmin, msg.sender);
  }

  /**
   * @dev Claim ENS reverse-resolver rights for this contract.
   * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
   */
  function setReverseResolver (address registrar) public onlyRole(ADMIN_ROLE) {
    IReverseResolver(registrar).claim(msg.sender);
  }

  /**
   * @dev Set a message as valid, to be queried by ERC1271 clients.
   */
  function markMessageSigned (bytes32 hash, uint256 expirationLength) public onlyRole(ADMIN_ROLE) {
    validSignatures[hash] = block.number + expirationLength;
  }

  /**
   * @dev Rescue ERC20 assets sent directly to this contract.
   */
  function withdrawForeignERC20 (address tokenContract) public onlyRole(ADMIN_ROLE) {
    IERC20 token = IERC20(tokenContract);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @dev Rescue ERC721 assets sent directly to this contract.
   */
  function withdrawForeignERC721 (address tokenContract, uint256 tokenId)
    public
    virtual
    onlyRole(ADMIN_ROLE)
  {
    IERC721(tokenContract).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId
    );
  }

  function withdrawEth () public onlyRole(ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
  }

}
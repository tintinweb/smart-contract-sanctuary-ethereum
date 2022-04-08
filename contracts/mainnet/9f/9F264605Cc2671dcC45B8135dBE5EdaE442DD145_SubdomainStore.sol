// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ENS.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev A basic interface for ENS resolvers.
 */
interface Resolver {
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
  function addr(bytes32 node) external view returns (address);
  function setAddr(bytes32 node, address addr) external;
  function setText(bytes32 node, string calldata key, string calldata value) external;
  function setContenthash(bytes32 node, bytes calldata hash) external;
  function setAddr(bytes32 node, uint coinType, bytes memory a) external;
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}

contract SubdomainStore is IERC721Receiver, Ownable, ApproveAndCallFallBack {

  struct Domain {
    string name;
    uint price;
  }

  //.eth
  bytes32 constant internal TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

  //0xbitcoin contract
  address internal xbtc = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

  //0xbitcoin miners guild contract
  address internal guild = 0x167152A46E8616D4a6892A6AfD8E52F060151C70;

  //ens registry
  ENS internal ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  //funds trackers
  uint256 internal devFunds = 0;
  uint256 internal guildFunds = 0;

  //share %
  uint256 internal devShare = 25;
  uint256 internal guildShare = 75;
  
  mapping (bytes32 => Domain) internal domains;
  
  constructor() {
    
  }
  
  /**
   * @dev Configures a domain for sale.
   * @param name The name to configure.
   * @param price The price in wei to charge for subdomain registrations
   */
  function configureDomain(string memory name, uint price) public onlyOwner {
    bytes32 label = keccak256(bytes(name));
    Domain storage domain = domains[label];

    if (keccak256(abi.encodePacked(domain.name)) != label) {
      // New listing
      domain.name = name;
    }

    domain.price = price;
  }

  function setShares(uint256 _devShare, uint256 _guildShare) external onlyOwner {
    require(_devShare+_guildShare==100 && _devShare >= 0 && _guildShare >= 0, "Invalid share values");
    devShare = _devShare;
    guildShare = _guildShare;
  }

  //Sets the address record for a resident ENS name
  function setResidentAddress(string calldata name, address addr, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setAddr(domainNode, addr);
  }

  //Sets the address record for a resident ENS name
  function setResidentAddress(string calldata name, uint coinType, bytes memory a, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setAddr(domainNode, coinType, a);
  }

  //Sets the text record for a resident ENS name
  function setResidentText(string calldata name, string calldata key, string calldata value, Resolver resolver) external onlyOwner{ 
    bytes32 label = keccak256(bytes(name)); 
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setText(domainNode, key, value);
  }

  //Sets the content record for a resident ENS name
  function setResidentContenthash(string calldata name, bytes calldata hash, Resolver resolver) external onlyOwner{  
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    resolver.setContenthash(domainNode, hash);
  }
  
  //Sets the resolver record for a resident ENS name
  function setResidentResolver(string calldata name, address resolver) external onlyOwner {
    bytes32 label = keccak256(bytes(name));
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
    ens.setResolver(domainNode, resolver);
  }
  
  function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
    // Get the subdomain so we can configure it
    ens.setSubnodeOwner(node, label, address(this));

    bytes32 subnode = keccak256(abi.encodePacked(node, label));
    // Set the subdomain's resolver
    ens.setResolver(subnode, address(resolver));

    // Set the address record on the resolver
    resolver.setAddr(subnode, subdomainOwner);

    // Pass ownership of the new subdomain to the registrant
    ens.setOwner(subnode, subdomainOwner);    
  }

  /**
   * @dev Registers a subdomain.
   * @param label The label hash of the domain to register a subdomain of.
   * @param subdomain The desired subdomain label.
   * @param subdomainOwner The account that should own the newly configured subdomain.
   */
  function register(bytes32 label, string memory subdomain, address subdomainOwner, address resolver) public {
    bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));

    bytes32 subdomainLabel = keccak256(bytes(subdomain));

    // Subdomain must not be registered already.
    require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0), "Subdomain must not be registered already");
    Domain storage domain = domains[label];

    // Domain must be available for registration
    require(keccak256(abi.encodePacked(domain.name)) == label, "Domain must be available for registration");

    // The account that gets the subdomain also needs to pay
    require(IERC20(xbtc).transferFrom(subdomainOwner, address(this), domain.price), "User must have paid");

    devFunds = devFunds + (domain.price * devShare / 100);
    guildFunds = guildFunds + (domain.price * guildShare / 100);

    doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function receiveApproval(address from, uint256, address token, bytes memory data) public override {
    require(token == xbtc, "Must pay in 0xBTC");

    bytes32 label; 
    string memory subdomain;
    address resolver;

    (label, subdomain, resolver) = abi.decode(data, (bytes32, string, address));

    register(label, subdomain, from, resolver);
  }

  function withdrawAndShare() public virtual {
    require(devFunds > 0 || guildFunds > 0 ,'nothing to withdraw');

    //prevent reentrancy
    uint256 devFee = devFunds;
    devFunds = 0;

    uint256 guildFee = guildFunds;
    guildFunds = 0;

    require(IERC20(xbtc).transfer(fappablo, devFee/2),'transfer failed');
    require(IERC20(xbtc).transfer(rms, devFee/2),'transfer failed');
    require(IERC20(xbtc).transfer(guild, guildFee),'transfer failed');
  }

  //Helper function to encode the data needed for ApproveAndCall
  function encodeData(bytes32 label, string calldata subdomain, address resolver) external pure returns (bytes memory data) {
    return abi.encode(label, subdomain, resolver);
  }

  //Helper function to get the label hash
  function encodeLabel(string calldata label) external pure returns (bytes32 encodedLabel) {
    return keccak256(bytes(label));
  }

  function getPrice (bytes32 label) external view returns (uint256 price){
    Domain storage data = domains[label];
    return data.price;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    //dev accounts
    address internal fappablo = 0xD915246cE4430cb893757bC5908990921344F02d; 
    address internal rms = 0xD73250F6c4a1cd2b604D59636edE5D1D3312AF83;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owners() public view virtual returns (address [2] memory ) {
        return [fappablo,rms];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require((owners()[0] == _msgSender()) || (owners()[1] == _msgSender()), "Ownable: caller is not the owner");
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
        address oldOwner = _msgSender();
        if(oldOwner == fappablo){
            fappablo = newOwner;
        }else{
            rms = newOwner;
        }
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external ;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
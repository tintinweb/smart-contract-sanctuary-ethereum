pragma solidity ^0.8.8;
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}
 
// move to interface folder
interface IENS{
    function resolver(bytes32 node) external view returns (address);
}

contract PhilandL1 {
     // The StarkNet core contract.
    IStarknetCore _starknetCore;
    IENS internal _ens; 
    address private _adminSigner;
    mapping(uint256 => uint256) public userBalances;

    // The selector of the "create_philand" l1_handler.
    uint256 constant CREATE_GRID_SELECTOR =
        230744737155971716570284140634551213064188756564393274009046094202533668423;

    uint256 constant CLAIM_L1_OBJECT_SELECTOR =
        1426524085905910661260502794228018787518743932072178038305015687841949115798;

    uint256 constant CLAIM_L2_OBJECT_SELECTOR =
    725729645710710348624275617047258825327720453914706103365608274738200251740;

    event LogCreatePhiland(address indexed l1Sender, uint256 ensname);
    event LogClaimL1NFT(uint256 ensname,uint256 contract_address,uint256 tokenid);
    event LogClaimL2Object(uint256 ensname,uint256 contract_address,uint256 tokenid);
    /**
      Initializes the contract state.
    */
    constructor(IStarknetCore starknetCore,IENS ens,address adminSigner
    ){
        _starknetCore = starknetCore;
        _ens = ens;
        _adminSigner = adminSigner;
    }
        
        //todo ens check and set ens method
    function createPhiland(
        uint256 l2ContractAddress,
        uint256 ensname
        ) external {
        
        emit LogCreatePhiland(msg.sender, ensname);        
        uint256[] memory payload = new uint256[](1);
        payload[0] = ensname;
        // Send the message to the StarkNet core contract.
        _starknetCore.sendMessageToL2(l2ContractAddress, CREATE_GRID_SELECTOR, payload);
    }

    function claimL1Object(
        uint256 l2ContractAddress,
        uint256 ensname,
        address contractAddress,
        uint256 tokenid
        ) external {

        emit LogClaimL1NFT(ensname,uint256(uint160(contractAddress)),tokenid);        
        uint256[] memory payload = new uint256[](3);
        payload[0] = ensname;
        payload[1] = uint256(uint160(contractAddress));
        payload[2] = tokenid;

        // Send the message to the StarkNet core contract.
        _starknetCore.sendMessageToL2(l2ContractAddress, CLAIM_L1_OBJECT_SELECTOR, payload);
    }

    struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
    }
    
    enum CouponType {
    Genesis,
    Author,
    Presale
    }


    function claimL2Object(
        uint256 l2ContractAddress,
        uint256 ensname,
        uint256 contractAddress,
        uint256 tokenid,
        Coupon memory coupon
        ) external {

        bytes32 digest = keccak256(
        abi.encode(CouponType.Presale, msg.sender)
        ); 
    
        require(
        _isVerifiedCoupon(digest, coupon), 
        'Invalid coupon'
        ); 
        emit LogClaimL2Object(ensname,contractAddress,tokenid);

        uint256[] memory payload = new uint256[](3);
        payload[0] = ensname;
        payload[1] = contractAddress;
        payload[2] = tokenid;

        // Send the message to the StarkNet core contract.
        _starknetCore.sendMessageToL2(l2ContractAddress, CLAIM_L2_OBJECT_SELECTOR, payload);
    }

    /// @dev check that the coupon sent was signed by the admin signer
	function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
		internal
		view
		returns (bool)
	{
		
		address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
		require(signer != address(0), 'ECDSA: invalid signature'); // Added check for zero address
		return signer == _adminSigner;
	}

    

    function toSplitUint(uint256 value) internal pure returns (uint256, uint256) {
    uint256 low = value & ((1 << 128) - 1);
    uint256 high = value >> 128;
    return (low, high);
    }


    function asciiToInteger(bytes32 x) internal pure returns (uint256) {
        uint256 y;
        for (uint256 i = 0; i < 32; i++) {
            uint256 c = (uint256(x) >> (i * 8)) & 0xff;
            if (48 <= c && c <= 57)
                y += (c - 48) * 10 ** i;
            else if (65 <= c && c <= 90)
                y += (c - 65 + 10) * 10 ** i;
            else if (97 <= c && c <= 122)
                y += (c - 97 + 10) * 10 ** i;
            else
                break;
        }
        return y;
    }

}

pragma solidity >=0.8.4;

import "./ENS.sol";

/**
 * The ENS registry contract.
 */
contract ENSRegistry is ENS {

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping (bytes32 => Record) records;
    mapping (address => mapping(address => bool)) operators;

    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node) {
        address owner = records[node].owner;
        require(owner == msg.sender || operators[owner][msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new ENS registrar.
     */
    constructor() public {
        records[0x0].owner = msg.sender;
    }

    /**
     * @dev Sets the record for a node.
     * @param node The node to update.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual override {
        setOwner(node, owner);
        _setResolverAndTTL(node, resolver, ttl);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual override {
        bytes32 subnode = setSubnodeOwner(node, label, owner);
        _setResolverAndTTL(subnode, resolver, ttl);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address owner) public virtual override authorised(node) {
        _setOwner(node, owner);
        emit Transfer(node, owner);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public virtual override authorised(node) returns(bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, owner);
        emit NewOwner(node, label, owner);
        return subnode;
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address resolver) public virtual override authorised(node) {
        emit NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

    /**
     * @dev Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 ttl) public virtual override authorised(node) {
        emit NewTTL(node, ttl);
        records[node].ttl = ttl;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) external virtual override {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node) public virtual override view returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node) public virtual override view returns (address) {
        return records[node].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public virtual override view returns (uint64) {
        return records[node].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) public virtual override view returns (bool) {
        return records[node].owner != address(0x0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param owner The address that owns the records.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address owner, address operator) external virtual override view returns (bool) {
        return operators[owner][operator];
    }

    function _setOwner(bytes32 node, address owner) internal virtual {
        records[node].owner = owner;
    }

    function _setResolverAndTTL(bytes32 node, address resolver, uint64 ttl) internal {
        if(resolver != records[node].resolver) {
            records[node].resolver = resolver;
            emit NewResolver(node, resolver);
        }

        if(ttl != records[node].ttl) {
            records[node].ttl = ttl;
            emit NewTTL(node, ttl);
        }
    }
}

pragma solidity >=0.8.4;

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

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}
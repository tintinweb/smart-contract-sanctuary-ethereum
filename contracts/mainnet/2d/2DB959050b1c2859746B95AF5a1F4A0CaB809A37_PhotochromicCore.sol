// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PhotochromicRegistrar.sol";
import "./PhotochromicResolver.sol";
import "./PhotochromicTools.sol";

contract PhotochromicCore is Ownable {

    // The PhotoChromic Registrar.
    PhotochromicRegistrar public registrar;
    // The PhotoChromic Resolver.
    PhotochromicResolver public resolver;
    // The ENS registry.
    ENS public immutable ens;
    // The period in which the ticket is valid.
    uint256 public ticketValidity = 4 weeks;
    // The grace period in which a user id can not be re-registered after its expiry.
    uint256 public gracePeriod = 12 weeks;
    // Price in wei (ETH).
    uint256 public pricePerYear;

    Profile[] public profiles;
    address public photochromicSignerAddress;

    // Only for tickets!
    // Mapping between user ids and addresses.
    mapping(bytes32 => address) private nodeToAddress;
    // Mapping between addresses and corresponding domain info.
    mapping(address => bytes) private addressToDomainInfo;

    event Ticket(address indexed user, bytes32 node, string userId, string profile, uint256 yrs, uint256 timestamp);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);

    struct Profile {
        // Profile name
        string name;
        // The price of the profile.
        uint128 price;
        // The amount of socials allowed to validate.
        uint128 info;
    }

    // Information stored to handle ticket purchases.
    struct DomainInfo {
        // The user identifier for which the the ticket was bought. Full ens name.
        string userId;
        // The profile for which the user paid.
        uint8 profileNum;
        // The amount of years for which the user paid.
        uint8 yrs;
        // The time of the ticket purchase.
        uint32 purchaseTime;
    }

    struct PhotoChromicRecord {
        uint32 livenessTime;
        string[DATA_FIELDS] contents;
        string userId;
        bytes32 ipfsHash;
        EcdsaSig sig;
    }

    constructor(
        PhotochromicRegistrar _registrar,
        PhotochromicResolver _resolver,
        ENS _ens,
        address _sigAddr
    ) {
        registrar = _registrar;
        resolver = _resolver;
        ens = _ens;
        photochromicSignerAddress = _sigAddr;
        pricePerYear = 0.01 ether;
    }

    function upgradeResolver(address newResolver) external onlyOwner {
        require(newResolver != address(0));
        resolver = PhotochromicResolver(newResolver);
    }

    function setTicketValidity(uint256 newTicketValidity) external onlyOwner {
        ticketValidity = newTicketValidity;
    }

    function setGracePeriod(uint256 newGracePeriod) external onlyOwner {
        gracePeriod = newGracePeriod;
    }

    function setPricePerYear(uint256 newPricePerYear) external onlyOwner {
        pricePerYear = newPricePerYear;
    }

    function lastLiveness(bytes32 node) external view returns (uint32) {
        (uint32 livenessTime,) = resolver.getValidityInfo(node);
        return livenessTime;
    }

    function getValidityInfo(bytes32 node) external view returns (uint32, uint32) {
        return resolver.getValidityInfo(node);
    }

    /**
      * Updates the liveness of a userId. The given signature needs to match `photochromicSignerAddress`.
      */
    function updateLiveness(
        bytes32 node,
        uint32 livenessTime,
        EcdsaSig memory sig
    ) external payable {
        require(registrar.balanceOf(msg.sender) == 1);
        bytes32 hash = keccak256(abi.encode(msg.sender, node, livenessTime));
        address signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer == photochromicSignerAddress, "liveness signature does not match contents");
        resolver.updateLiveness(node, livenessTime);
    }

    /**
      * Renews the expiry of a userId.
      */
    function renew(bytes32 node, uint256 yrs) external payable {
        uint256 price = pricePerYear * yrs;
        require(price <= msg.value, "insufficient amount paid");
        resolver.updateExpiry(node, uint32(365 days * yrs));
    }


    function updateSignerAddress(address newPhotochromicSignerAddress) external onlyOwner {
        photochromicSignerAddress = newPhotochromicSignerAddress;
    }

    function encodeDomainInfo(
        // The time of the ticket purchase.
        uint256 purchaseTime,
        // The amount of years (expiry).
        uint256 yrs,
        // The profile for which the user payed for.
        uint8 profileNum,
        // The user identifier to register.
        string memory userId
    ) internal pure returns (bytes memory) {
        // [purchaseTime, years, profile, userId]
        return abi.encodePacked(
            uint32(purchaseTime),
            uint8(yrs),
            uint8(profileNum),
            userId
        );
    }

    function getProfileNum(string memory profile) internal view returns (uint256) {
        for (uint256 p = 0; p < profiles.length; p++) {
            if (keccak256(bytes(profiles[p].name)) == keccak256 (bytes(profile))) {
                return p;
            }
        }
        revert("unknown profile");
    }

    function decodeDomainInfo(bytes memory bs) internal pure returns (DomainInfo memory) {
        DomainInfo memory domainInfo = DomainInfo("",0,0,0);
        if (bs.length < 7) return domainInfo;

        domainInfo.purchaseTime = (uint32(uint8(bs[0])) << 24) | (uint32(uint8(bs[1])) << 16)
                                | (uint32(uint8(bs[2])) << 8)  |  uint32(uint8(bs[3]));
        domainInfo.yrs = uint8(bs[4]);
        domainInfo.profileNum = uint8(bs[5]);
        bytes memory userId = new bytes(bs.length - 6);
        for (uint256 i = 6; i < bs.length; i++) {
            userId[i - 6] = bs[i];
        }
        domainInfo.userId = string(userId);
        return domainInfo;
    }

    /**
     * Returns the list of profile names.
     */
    function getProfileNames() external view returns (string[] memory) {
        string[] memory profileNames = new string[](profiles.length);
        for (uint i=0; i < profiles.length; i++) {
            profileNames[i] = profiles[i].name;
        }
        return profileNames;
    }

    /**
     * Returns the price in ETH.
     */
    function getPrice(string calldata profile, uint256 yrs) public view returns (uint256) {
        require(0 < yrs, "years < 1");
        uint128 basePrice = profiles[getProfileNum(profile)].price;
        return basePrice + pricePerYear * (yrs - 1);
    }

    /**
     * Returns the amount of socials allowed to mint.
     */
    function getSocialsAmount(string calldata profile) external view returns (uint256) {
        return profiles[getProfileNum(profile)].info & 0xf; // lowest 4 bits
    }

    /**
     * Overwrites all the profiles.
     */
    function setProfiles(Profile[] calldata newProfiles) external onlyOwner {
        require(newProfiles.length != 0);
        delete profiles;
        for (uint i = 0; i < newProfiles.length; i++) {
            profiles.push(Profile({name: newProfiles[i].name, price:newProfiles[i].price, info: newProfiles[i].info}));
        }
    }

    function purchase(
        string memory userId,
        string calldata profile,
        uint256 yrs
    ) external payable {
        require(bytes(userId).length > 0);

        uint256 price = getPrice(profile, yrs);
        require(price <= msg.value, "insufficient amount paid");

        // If the baseNode is not the same as the registrar's baseNode then the node should
        // be owned by the sender.
        (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(userId);
        bytes32 node = PhotochromicTools.namehash(baseNode, label);
        if (!registrar.isBaseNode(baseNode)) {
            // The sender needs to be the owner of the node if it is not a
            // PhotoChromic identity.
            require(ens.owner(node) == msg.sender);
        }

        // Check whether someone already owns a ticket for this userId.
        address addressOwningUserId = nodeToAddress[node];
        if (addressOwningUserId != address(0)) {
            DomainInfo memory existingDomainInfo = decodeDomainInfo(addressToDomainInfo[addressOwningUserId]);
            // The sender of purchase is not the owner of the ticket, so we check whether the existing ticket is still
            // valid. If so, revert. The sender can not buy a ticket for the given userId.
            if (addressOwningUserId != msg.sender) {
                require(
                    existingDomainInfo.purchaseTime + ticketValidity < block.timestamp,
                    "a ticket was already purchased for this user id and has not yet expired"
                );
            }
            // The sender owns the ticket or the ticket expired.
            _burnTicket(node, addressOwningUserId);
        }

        // In case there is no (valid) ticket, someone else could still have registered the userId.
        (, uint32 expiryTime) = resolver.getValidityInfo(node);
        if (expiryTime != 0) {
            // Someone owns the user id already, check whether it expired.
            require(
                expiryTime + gracePeriod < block.timestamp,
                "this userId was already minted but is still valid/in its grace period"
            );

            // The node expired and is not within the grace period.
            _burn(node, baseNode, PhotochromicTools.labelhash(label), ens.owner(node));
        }

        // Check whether the user already owns a valid ticket for a userId (any, can be different from this one).
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
        if (bytes(domainInfo.userId).length != 0) {
            require(
                domainInfo.purchaseTime + ticketValidity < block.timestamp,
                "a ticket was purchased for the userId and is not yet expired"
            );

            _burnTicket(node, msg.sender);
        }

        // Create a new ticket for the given userId.
        nodeToAddress[node] = msg.sender;
        uint32 currentTime = uint32(block.timestamp);
        addressToDomainInfo[msg.sender] = encodeDomainInfo(currentTime, yrs, uint8(getProfileNum(profile)), userId);
        emit Ticket(msg.sender, node, userId, profile, yrs, currentTime);
    }

    // Checks whether the given node is still available.
    // 1. There is no (valid) ticket for this node.
    // 2. The node is not yet registered or in its grace period.
    function available(bytes32 node) external view returns (bool) {
        // (1)
        address addresOwningUserId = nodeToAddress[node];
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[addresOwningUserId]);
        if (block.timestamp < domainInfo.purchaseTime + ticketValidity) {
            // The ticket is still valid.
            return false;
        }

        // (2)
        (, uint32 expiryTime) = resolver.getValidityInfo(node);
        if (block.timestamp < expiryTime + gracePeriod) {
            // The ticket is not expired/in its grace period.
            return false;
        }

        // The given user id is available for purchase.
        return true;
    }

    // Checks whether there is a valid userId ticket for the given requester.
    // 1. The requester != 0x00.
    // 2. There is a ticket owned by the requester.
    // 3. The ticket is still valid.
    function isValidTicket(bytes32 node, address requester) external view returns (bool) {
        address addresOwningUserId = nodeToAddress[node];
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[addresOwningUserId]);
        return requester != address(0) && addresOwningUserId == requester && block.timestamp <= domainInfo.purchaseTime + ticketValidity;
    }

    /**
     * Removes the ticket for the given node.
     */
    function burnTicket(bytes32 node) external {
        address userAddress = nodeToAddress[node];
        require(msg.sender == userAddress || msg.sender == owner());
        _burnTicket(node, userAddress);
    }

    function _burnTicket(bytes32 node, address holder) internal {
        delete nodeToAddress[node];
        delete addressToDomainInfo[holder];
    }

    /**
     * Burns the userId at the registrar.
     * This is limited to PhotoChromic subdomains.
     */
    function burn(string memory userId) external {
        (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(userId);
        bytes32 node = PhotochromicTools.namehash(baseNode, label);
        address nodeOwner = registrar.ownerOf(uint256(node));
        require(msg.sender == nodeOwner || msg.sender == owner(), "user does not own the given userId");
        bytes32 labelHash = keccak256(abi.encodePacked(label));
        _burn(node, baseNode, labelHash, nodeOwner);
    }

    function clearRecords() external {
        bytes32 node = registrar.getNode(msg.sender);
        registrar.removeNode(msg.sender);
        resolver.clearPCRecords(node);
        resolver.deleteValidityInfo(node);
    }

    function _burn(bytes32 node, bytes32 baseNode, bytes32 labelHash, address holder) internal {
        registrar.burn(labelHash, baseNode);
        registrar.removeNode(holder);
        resolver.clearPCRecords(node);
        resolver.deleteValidityInfo(node);
    }

    /**
     * Transfers out the specified amount to the owner account.
     */
    function transferBalance(uint256 amount) external onlyOwner {
        require((amount <= address(this).balance) && (amount > 0));
        address payable receiver = payable(msg.sender);
        receiver.transfer(amount);
    }

    /**
     * Transfer ownership of resolver to a new address
     */
    function setResolverOwner(address newOwner) external onlyOwner {
        resolver.transferOwnership(newOwner);
    }

    /**
     * Returns the address linked to the ticket of the given node.
     */
    function getTicketAddress(bytes32 node) external view returns (address) {
        return nodeToAddress[node];
    }

    /**
     * Returns the user identifier of the ticket linked to the given address.
     */
    function getTicketUserId(address userAddress) public view returns (string memory userId) {
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[userAddress]);
        return domainInfo.userId;
    }

    /**
     * Returns the user identifier corresponding to the sender's ticket.
     */
    function getTicketUserId() external view returns (string memory userId) {
        return getTicketUserId(msg.sender);
    }

    /**
     * Returns the profile corresponding to the ticket of the sender.
     */
    function getTicketProfile() external view returns (string memory profile, uint8 yrs) {
        DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
        if (bytes(domainInfo.userId).length == 0) return ("", 0);
        return (profiles[domainInfo.profileNum].name, domainInfo.yrs);
    }

    /**
     * Creates an identity if the sender has a ticket for the given userId and the signature matches
     * `photochromicSignerAddress`.
     */
    function mint(
        PhotoChromicRecord calldata data,
        ValidatedTextRecord[] calldata texts,
        ValidatedAddrRecord[] calldata addrs,
        string calldata avatar
    ) external {
        bytes32 node;
        {
            (string memory label, bytes32 baseNode) = PhotochromicTools.decomposeEns(data.userId);
            node = PhotochromicTools.namehash(baseNode, label);

            // Check ticket exists for the sender.
            require(nodeToAddress[node] == msg.sender, "need to purchase a ticket first");

            // Check the signature of the KYC data.
            require(validPhotoChromicRecord(msg.sender, data), "signature does not match contents");
            registrar.register(msg.sender, address(resolver), PhotochromicTools.labelhash(label), baseNode, data.ipfsHash);
            {
                DomainInfo memory domainInfo = decodeDomainInfo(addressToDomainInfo[msg.sender]);
                // Check if the request did not exceed the amount of validated records.
                require(texts.length + addrs.length <= profiles[domainInfo.profileNum].info & 0xf);

                if (registrar.isBaseNode(baseNode)) {
                    emit NameRegistered(uint(node), msg.sender, uint32(domainInfo.purchaseTime + (365 days * uint32(domainInfo.yrs))));
                }

                resolver.setPCRecords(node, data.userId, data.contents, msg.sender, profiles[domainInfo.profileNum].name);
                resolver.setValidityInfo(
                    node,
                    uint32(domainInfo.purchaseTime + (365 days * uint32(domainInfo.yrs))),
                    data.livenessTime
                );
                resolver.setValidatedTextRecords(node, texts);
                resolver.setValidatedAddrRecords(node, addrs);
                if (bytes(avatar).length > 0) {
                    resolver.setText(node, "avatar", avatar);
                }
            }
        }
        // Remove ticket.
        _burnTicket(node, msg.sender);
    }

    function validPhotoChromicRecord(address sender, PhotoChromicRecord calldata data) internal view returns (bool) {
        bytes32 h = keccak256(abi.encode(sender, data.livenessTime, data.contents, data.userId, data.ipfsHash));
        address signer = ecrecover(h, data.sig.v, data.sig.r, data.sig.s);
        return signer == photochromicSignerAddress;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/root/Controllable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./PhotochromicTools.sol";

contract PhotochromicRegistrar is ERC721Enumerable, Controllable {

    // The ENS registry.
    ENS public immutable ens;
    // The namehash of the TLD this registrar owns (e.g., `.eth`).
    bytes32 public baseNode;
    string public baseNodeString;

    // Mapping from the tokenId (ENS namehash) to IPFS metadata hash.
    mapping(uint256 => bytes32) hashes;
    // Mapping from the owner of a photochromic identity to ENS namehash.
    mapping(address => bytes32) nodes;

    constructor(ENS _ens, bytes32 _baseNode, string memory _baseNodeString) ERC721("Photochromic Identity", "PCI") {
        ens = _ens;
        baseNode = _baseNode;
        baseNodeString = _baseNodeString;
    }

    function isBaseNode(bytes32 node) external view returns (bool) {
        return node == baseNode;
    }

    function burn(bytes32 labelHash, bytes32 baseNodeUser) external onlyController {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(baseNodeUser, labelHash)));
        _burn(tokenId);
        delete hashes[tokenId];
        if (baseNodeUser == baseNode) {
            ens.setSubnodeRecord(baseNode, labelHash, address(this), address(0), 0);
        }
    }

    function nodeOwnedBy(bytes32 node, address holder) external view returns (bool) {
        return nodes[holder] == node;
    }

    function getNode(address holder) external view returns (bytes32) {
        return nodes[holder];
    }

    function removeNode(address holder) external onlyController {
        delete nodes[holder];
    }

    // Returns true if the specified name is available for registration.
    function available(uint256 namehash) public view returns (bool) {
        return !_exists(namehash);
    }

    function isUserIdAvailable(uint256 labelHash) external view returns (bool) {
        uint256 nh = uint256(keccak256(abi.encodePacked(baseNode, bytes32(labelHash))));
        return available(nh);
    }

    function register(
        address user,
        address resolver,
        bytes32 labelHash,
        bytes32 userBaseNode,
        bytes32 ipfsHash
    ) external onlyController returns (uint256) {
        require(balanceOf(user) == 0, "already has a photochromic identity");
        uint256 tokenId = uint256(keccak256(abi.encodePacked(userBaseNode, labelHash)));
        require(available(tokenId), "name already has a photochromic identity");
        _safeMint(user, tokenId);
        if (userBaseNode == baseNode) {
            ens.setSubnodeRecord(baseNode, labelHash, user, resolver, 0);
        }
        hashes[tokenId] = ipfsHash;
        nodes[user] = bytes32(tokenId);
        return tokenId;
    }

    // Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory ipfsHash = PhotochromicTools.ipfsToString(hashes[tokenId]);
        return string(abi.encodePacked("ipfs://", ipfsHash));
    }

    function _transfer(address, address, uint256) internal pure override(ERC721) {
        revert("transfer is not allowed for this token");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./PhotochromicRegistrar.sol";
import "./Resolver.sol";


struct ValidatedTextRecord {
    string key;
    string value;
    uint32 timestamp;
    EcdsaSig sig;
}

struct ValidatedAddrRecord {
    uint coinType;
    bytes value;
    uint32 timestamp;
    EcdsaSig sig;
}

contract PhotochromicResolver is Resolver {

    address private signerAddress;
    mapping(string => mapping(string => bytes32)) reverseRecords;

    constructor(
        ENS _ens,
        PhotochromicRegistrar _registrar,
        address _signerAddress
    ) ResolverValidated(_ens, _registrar) {
        signerAddress = _signerAddress;
    }

    function setPCRecords(
        bytes32 node,
        string memory userId,
        string[DATA_FIELDS] calldata contents,
        address sender,
        string memory profile
    ) external onlyOwner {
        photochromicTexts[node] = Validator.packPhotochromicRecord(
            userId, profile,
            Validator.packKYCData(contents),
            uint32(block.timestamp)
        );

        // Preserve original ENS resolver
        address oldResolver = ens.resolver(node);
        if (oldResolver != address(this)) resolvers[node] = oldResolver;

        // KYC data can be empty.
        if (bytes(contents[0]).length != 0) {
            emit TextChanged(node, Validator.PC_FIRSTNAME, Validator.PC_FIRSTNAME);
        }
        if (bytes(contents[1]).length != 0) {
            emit TextChanged(node, Validator.PC_LASTNAME, Validator.PC_LASTNAME);
        }
        if (bytes(contents[2]).length != 0) {
            emit TextChanged(node, Validator.PC_EMAIL, Validator.PC_EMAIL);
        }
        if (bytes(contents[3]).length != 0) {
            emit TextChanged(node, Validator.PC_BIRTHDATE, Validator.PC_BIRTHDATE);
        }
        if (bytes(contents[4]).length != 0) {
            emit TextChanged(node, Validator.PC_NATIONALITY, Validator.PC_NATIONALITY);
        }

        emit TextChanged(node, Validator.PC_USERID, Validator.PC_USERID);
        emit TextChanged(node, Validator.PC_PROFILE, Validator.PC_PROFILE);

        emit TextChanged(node, Validator.PC_USERID, Validator.PC_USERID);
        emit TextChanged(node, Validator.PC_PROFILE, Validator.PC_PROFILE);

        _addresses[node][60] = Validator.concatTimestamp(addressToBytes(sender), uint32(block.timestamp));
        emit TextChanged(node, "avatar", "avatar");
    }

    function clearPCRecords(bytes32 node) external onlyOwner {
        delete photochromicTexts[node];
        setAddr(node, 60, addressToBytes(address(0))); // COIN_TYPE_ETH
    }

    function setValidatedRecords(
        bytes32 node,
        ValidatedTextRecord[] calldata textRecords,
        ValidatedAddrRecord[] calldata addressRecords
    ) external authorised(node) {
        _setValidatedTextRecords(node, textRecords);
        _setValidatedAddrRecords(node, addressRecords);
    }

    function setValidatedTextRecords(bytes32 node, ValidatedTextRecord[] calldata list) external authorised(node) {
        _setValidatedTextRecords(node, list);
    }

    function _setValidatedTextRecords(bytes32 node, ValidatedTextRecord[] calldata list) internal {
        address holder = ens.owner(node);
        for (uint i = 0; i < list.length; i++) {
            bytes32 h = keccak256(abi.encode(holder, list[i].key, list[i].value, list[i].timestamp));
            address signer = ecrecover(h, list[i].sig.v, list[i].sig.r, list[i].sig.s);
            uint32 t = signer == signerAddress ? list[i].timestamp : 1; // 1 == invalid
            texts[node][list[i].key] = string(Validator.concatTimestamp(bytes(list[i].value), t));
            reverseRecords[list[i].key][list[i].value] = node;
        }
    }

    function setValidatedAddrRecords(bytes32 node, ValidatedAddrRecord[] calldata list) external authorised(node) {
        _setValidatedAddrRecords(node, list);
    }

    function _setValidatedAddrRecords(bytes32 node, ValidatedAddrRecord[] calldata list) internal {
        address holder = ens.owner(node);
        for (uint i = 0; i < list.length; i++) {
            bytes32 h = keccak256(abi.encode(holder, list[i].coinType, list[i].value, list[i].timestamp));
            address signer = ecrecover(h, list[i].sig.v, list[i].sig.r, list[i].sig.s);
            uint32 t = signer == signerAddress ? list[i].timestamp : 1; // 1 == invalid
            _addresses[node][list[i].coinType] = Validator.concatTimestamp(bytes(list[i].value), t);
        }
    }

    function lookup(string calldata key, string calldata value) external view returns (bytes32) {
        return reverseRecords[key][value];
    }

    function setValidityInfo(
        bytes32 node,
        uint32 expiryTime,
        uint32 livenessTime
    ) public onlyOwner {
        texts[node][Validator.KYC_VALIDITYINFO] = Validator.packValidityInfo(livenessTime, expiryTime);
    }

    function deleteValidityInfo(bytes32 node) external onlyOwner {
        delete texts[node][Validator.KYC_VALIDITYINFO];
    }

    function getValidityInfo(bytes32 node) public view returns (uint32, uint32) {
        string memory record = texts[node][Validator.KYC_VALIDITYINFO];
        return Validator.getValidityInfo(bytes(record));
    }

    function updateLiveness(
        bytes32 node,
        uint32 livenessTime
    ) external onlyOwner {
        (, uint32 expiryTime) = getValidityInfo(node);
        setValidityInfo(node, expiryTime, livenessTime);
    }

    function updateExpiry(
        bytes32 node,
        // The duration for which you want to renew (in seconds).
        // e.g. 86400 is a day.
        uint32 duration
    ) external onlyOwner {
        (uint32 livenessTime, uint32 expiryTime) = getValidityInfo(node);
        setValidityInfo(node, expiryTime + duration, livenessTime);
    }

    /**
     * Returns whether the given node (i.e. identity/domain/...) is still valid.
     * A node is valid if and only if:
     *  1. The node is still owned by the address used during the onboarding.
     *  2. The address record is not been overwritten.
     */
    function isValidNode(bytes32 node) external view returns (bool) {
        (ValidationStatus status, bytes memory a, ) = validatedAddr(node, 60);
        return status == ValidationStatus.VALIDATED && ens.owner(node) == bytesToAddress(a);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library PhotochromicTools {
    bytes constant SHA256_MULTIHASH = hex"1220";
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /// @return The IPFS hash in base58
    function ipfsToString(bytes32 ipfs) external pure returns (string memory) {
        return toBase58(concat(SHA256_MULTIHASH, toBytes(ipfs)));
    }

    /// @dev Converts hex string to base 58
    function toBase58(bytes memory source) internal pure returns (string memory) {
        uint8[] memory digits = new uint8[](48);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        //return digits;
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function toBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = input[i];
        }
        return output;
    }

    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (string memory) {
        string memory output = "";
        for (uint256 i = 0; i < indices.length; i++) {
            string memory temp = string(abi.encodePacked(output, ALPHABET[indices[i]]));
            output = temp;
        }
        return output;
    }

    function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
        bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
        uint256 i = 0;
        for (; i < byteArray.length; i++) {
            returnArray[i] = byteArray[i];
        }
        for (; i < (byteArray.length + byteArray2.length); i++) {
            returnArray[i] = byteArray2[i - byteArray.length];
        }
        return returnArray;
    }


    function namehash(bytes32 baseNodeHash, string memory label) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(baseNodeHash, keccak256(abi.encodePacked(label))));
    }

    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(label));
    }

    function baseNode(bytes memory ensName) internal pure returns (bytes32) {
        uint len = labelLength(ensName, 0);
        return namehashFrom(ensName, len+1);
    }

    function decomposeEns(string memory ensName) external pure returns (string memory, bytes32) {
        uint len = labelLength(bytes(ensName), 0);
        if (len < 1) revert();
        bytes memory result = new bytes(len);
        for(uint i = 0; i < len; i++) {
            result[i] = bytes(ensName)[i];
        }
        return (string(result), namehashFrom(bytes(ensName), len+1));
    }


    function namehashFrom(bytes memory ensName, uint i) internal pure returns (bytes32) {
        if (ensName.length <= i)
            return 0;

        uint len = labelLength(ensName, i);

        return keccak256(abi.encodePacked(namehashFrom(ensName, i+len+1), keccak(ensName, i, len)));
    }

    function labelLength(bytes memory ensName, uint i) private pure returns (uint) {
        uint len = 0;
        while (i+len != ensName.length && ensName[i+len] != 0x2e) {
            len++;
        }
        return len;
    }

    function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
        require(offset + len <= data.length);
        assembly {
            ret := keccak256(add(add(data, 32), offset), len)
        }
    }
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IInterfaceResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/PubkeyResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";

import "./PhotochromicRegistrar.sol";
import "./Validator.sol";

abstract contract ResolverValidated is AddrResolver, TextResolver, Ownable {
    using Strings for uint256;

    ENS immutable ens;
    PhotochromicRegistrar immutable registrar;

    // A mapping from node => resolver address.
    mapping(bytes32 => address) resolvers;

    constructor(
        ENS _ens,
        PhotochromicRegistrar _registrar
    ) {
        ens = _ens;
        registrar = _registrar;
    }

    function isAuthorised(bytes32 node) internal override view returns(bool) {
        return msg.sender == ens.owner(node) || msg.sender == owner();
    }

    function supportsInterface(bytes4 interfaceId) virtual public override(AddrResolver, TextResolver) pure returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setResolver(bytes32 node, address _resolver) public authorised(node) {
        require(_resolver != address(this));
        resolvers[node] = _resolver;
    }

    function resolver(bytes32 node) public view returns (address) {
        return resolvers[node];
    }

    // AddrResolver (IAddrResolver, IAddressResolver)
    function addr(bytes32 node, uint coinType) public override(AddrResolver) view returns (bytes memory) {
        (, bytes memory a, ) = validatedAddr(node, coinType);
        return a;
    }

    function validatedAddr(bytes32 node, uint coinType) public view returns (ValidationStatus, bytes memory, uint32) {
        bytes memory a = _addresses[node][coinType];
        if (a.length != 0 || resolver(node) == address(0)) {
            (bytes memory v, uint32 t) = Validator.extractTimestamp(a);
            if (t == 0) return (ValidationStatus.UNVALIDATED, v, 0);
            if (t == 1) return (ValidationStatus.INVALID, v, 0);
            if (node != registrar.getNode(ens.owner(node))) return (ValidationStatus.INVALID, v, t);
            return (ValidationStatus.VALIDATED, v, t);
        }
        return (ValidationStatus.UNVALIDATED, IAddressResolver(resolver(node)).addr(node, coinType), 0);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public override(AddrResolver) authorised(node) {
        _addresses[node][coinType] = Validator.concatTimestamp(a, 0);
        emit AddressChanged(node, coinType, a);
        if (coinType == 60) emit AddrChanged(node, bytesToAddress(a));
    }

    // TextResolver (ITextResolver)
    mapping(bytes32 => string) photochromicTexts;

    function text(bytes32 node, string calldata key) public override(TextResolver) view returns (string memory) {
        (, string memory value, ) = validatedText(node, key);
        return value;
    }

    function validatedText(bytes32 node, string calldata key) public view returns (ValidationStatus, string memory, uint32) {
        string memory value = _text(node, key);
        if (bytes(value).length == 0 && keccak256(abi.encodePacked(key)) == keccak256("avatar")) {
            string memory a = Strings.toHexString(uint160(address(registrar)), 20);
            string memory nodeString = uint256(node).toString();
            ValidationStatus validationStatus = ValidationStatus.VALIDATED;
            if(node != registrar.getNode(ens.owner(node))){
                validationStatus = ValidationStatus.INVALID;
            }
            return (validationStatus, string(abi.encodePacked("eip155:1/erc721:", a, "/", nodeString)), 0);
        }
        if (bytes(value).length != 0 || resolver(node) == address(0)) {
            (bytes memory v, uint32 t) = Validator.extractTimestamp(bytes(value));
            if (t == 0) return (ValidationStatus.UNVALIDATED, string(v), 0);
            if (t == 1) return (ValidationStatus.INVALID, string(v), 0);
            if (node != registrar.getNode(ens.owner(node))) return (ValidationStatus.INVALID, string(v), t);
            return (ValidationStatus.VALIDATED, string(v), t);
        }
        return (ValidationStatus.UNVALIDATED, ITextResolver(resolver(node)).text(node, key), 0);
    }

    function _text(bytes32 node, string calldata key) internal view returns (string memory) {
        if (Validator.isPhotochromicRecord(key)) {
            return Validator.getPhotochromicRecord(key, bytes(photochromicTexts[node]));
        }
        return texts[node][key];
    }

    function setText(bytes32 node, string calldata key, string calldata value) public override(TextResolver) authorised(node) {
        require(!Validator.isIORecord(key));
        if (bytes(value).length == 0 ) {
            delete texts[node][key];
        } else {
            texts[node][key] = string(Validator.concatTimestamp(bytes(value), 0));
        }
        emit TextChanged(node, key, key);
    }
}

abstract contract Resolver is ABIResolver, ContentHashResolver, IInterfaceResolver, NameResolver, PubkeyResolver, Multicallable, ResolverValidated {

    function supportsInterface(bytes4 interfaceId) public override(ABIResolver, ContentHashResolver, NameResolver, PubkeyResolver, Multicallable, ResolverValidated) pure returns (bool) {
        return interfaceId == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceId);
    }

    // ABIResolver
    function ABI(bytes32 node, uint256 contentTypes) public override(ABIResolver) view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];
        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }
        if (resolver(node) == address(0)) return (0, bytes(""));
        return IABIResolver(resolver(node)).ABI(node, contentTypes);
    }

    // ContentHashResolver
    function contenthash(bytes32 node) public override(ContentHashResolver) view returns (bytes memory) {
        bytes memory h = hashes[node];
        if (h.length != 0 || resolver(node) == address(0)) return h;
        return IContentHashResolver(resolver(node)).contenthash(node);
    }

    // InterfaceResolver (IInterfaceResolver)
    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

    function interfaceImplementer(bytes32 node, bytes4 interfaceID) public view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }
        address a = addr(node);
        if(a == address(0)) {
            return _interfaceImplementer(node, interfaceID);
        }
        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", type(IERC165).interfaceId));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            return _interfaceImplementer(node, interfaceID);
        }
        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            return _interfaceImplementer(node, interfaceID);
        }
        return a;
    }

    function _interfaceImplementer(bytes32 node, bytes4 interfaceID) internal view returns (address) {
        if (resolver(node) == address(0)) return address(0);
        return IInterfaceResolver(resolver(node)).interfaceImplementer(node, interfaceID);
    }

    function name(bytes32 node) public override(NameResolver) view returns (string memory) {
        string memory name = names[node];
        if (bytes(name).length != 0 || resolver(node) == address(0)) return name;
        return INameResolver(resolver(node)).name(node);
    }

    function pubkey(bytes32 node) public override(PubkeyResolver) view returns (bytes32 x, bytes32 y) {
        PublicKey memory key = pubkeys[node];
        if (key.x != 0 || key.y != 0 || resolver(node) == address(0)) return (key.x, key.y);
        return IPubkeyResolver(resolver(node)).pubkey(node);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMulticallable.sol";
import "./SupportsInterface.sol";

abstract contract Multicallable is IMulticallable, SupportsInterface {
    function multicall(bytes[] calldata data) external override returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) public override virtual pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

abstract contract ABIResolver is IABIResolver, ResolverBase {
    mapping(bytes32=>mapping(uint256=>bytes)) abis;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) virtual external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) virtual override external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IAddrResolver.sol";
import "./IAddressResolver.sol";

abstract contract AddrResolver is IAddrResolver, IAddressResolver, ResolverBase {
    uint constant private COIN_TYPE_ETH = 60;

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) virtual external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) virtual override public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) virtual override public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IAddrResolver).interfaceId || interfaceID == type(IAddressResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IContentHashResolver.sol";

abstract contract ContentHashResolver is IContentHashResolver, ResolverBase {
    mapping(bytes32=>bytes) hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) virtual external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) virtual external override view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IContentHashResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(bytes32=>string) names;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName) virtual external authorised(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) virtual override external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IPubkeyResolver.sol";

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) virtual external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IPubkeyResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(bytes32=>mapping(string=>string)) texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) virtual override external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ITextResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct EcdsaSig {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

enum ValidationStatus {
    VALIDATED,
    UNVALIDATED,
    INVALID
}

uint8 constant DATA_FIELDS = 5;

library Validator {
    string constant KYC_VALIDITYINFO = string(abi.encodePacked("io.photochromic.kyc"));
    bytes constant IO_PREFIX = bytes("io.photochromic.");

    function isIORecord(string calldata key) public pure returns (bool) {
        bytes memory keyBytes = bytes(key);
        if (keyBytes.length < IO_PREFIX.length) return false;
        for (uint i = 0; i < IO_PREFIX.length; i++) {
            if (IO_PREFIX[i] != keyBytes[i]) return false;
        }
        return true;
    }

    string constant PC_FIRSTNAME = string(abi.encodePacked("io.photochromic.firstname"));
    string constant PC_LASTNAME = string(abi.encodePacked("io.photochromic.lastname"));
    string constant PC_EMAIL = string(abi.encodePacked("io.photochromic.email"));
    string constant PC_BIRTHDATE = string(abi.encodePacked("io.photochromic.birthdate"));
    string constant PC_NATIONALITY = string(abi.encodePacked("io.photochromic.nationality"));
    string constant PC_USERID = string(abi.encodePacked("io.photochromic.userid"));
    string constant PC_PROFILE = string(abi.encodePacked("io.photochromic.profile"));

    function isPhotochromicRecord(string calldata key) public pure returns (bool) {
        bytes32 k = keccak256(abi.encodePacked(key));
        return
            k == keccak256(bytes(PC_FIRSTNAME)) ||
            k == keccak256(bytes(PC_LASTNAME)) ||
            k == keccak256(bytes(PC_EMAIL)) ||
            k == keccak256(bytes(PC_BIRTHDATE)) ||
            k == keccak256(bytes(PC_NATIONALITY)) ||
            k == keccak256(bytes(PC_USERID)) ||
            k == keccak256(bytes(PC_PROFILE));
    }

    function getPhotochromicRecord(string calldata key, bytes calldata record) public pure returns (string memory) {
        uint8 index = getPhotochromicRecordIndex(key);
        uint256 skipBytes = 4;
        if (4 < record.length) {
            uint32 t = (uint32(uint8(record[0])) << 24) 
                     | (uint32(uint8(record[1])) << 16) 
                     | (uint32(uint8(record[2])) << 8) 
                     |  uint32(uint8(record[3]));
            do {
                index -= 1;
                uint8 lengthInBytes = uint8(record[skipBytes]);
                skipBytes += 1;
                if (index == 0) {
                    // copy string from recordBytes
                    bytes memory result = new bytes(lengthInBytes);
                    uint256 stringStart = skipBytes;
                    for (uint256 i = 0; i < lengthInBytes; i++) {
                        result[i] = record[stringStart + i];
                    }
                    return string(concatTimestamp(result, t));
                }
                skipBytes += lengthInBytes;
            } while (0 < index);
        }
        return "";
    }

    function getPhotochromicRecordIndex(string calldata key) private pure returns (uint8) {
        bytes32 k = keccak256(abi.encodePacked(key));
        if (k == keccak256(bytes(PC_FIRSTNAME)))   return 1;
        if (k == keccak256(bytes(PC_LASTNAME)))    return 2;
        if (k == keccak256(bytes(PC_EMAIL)))       return 3;
        if (k == keccak256(bytes(PC_BIRTHDATE)))   return 4;
        if (k == keccak256(bytes(PC_NATIONALITY))) return 5;
        if (k == keccak256(bytes(PC_USERID))) return 6;
        // Only other possible index is `PC_PROFILE`.
        // List of keys in `isPhotochromicRecord`.
        return 7;
    }

    function getValidityInfo(bytes calldata record) public pure returns (uint32, uint32) {
        if(record.length != 8) return (0, 0);
        uint32 liveness = (uint32(uint8(record[0])) << 24) | (uint32(uint8(record[1])) << 16) | (uint32(uint8(record[2])) << 8) | uint32(uint8(record[3]));
        uint32 expiry = (uint32(uint8(record[4])) << 24) | (uint32(uint8(record[5])) << 16) | (uint32(uint8(record[6])) << 8) | uint32(uint8(record[7]));
        return (liveness, expiry);
    }

    function packValidityInfo(uint32 livenessTime, uint32 expiryTime) public pure returns (string memory) {
        return string(abi.encodePacked(livenessTime, expiryTime));
    }

    function packKYCData(string[DATA_FIELDS] calldata contents) public pure returns (string memory) {
        return string(abi.encodePacked(
            abi.encodePacked(
                uint8(bytes(contents[0]).length),
                bytes(contents[0]),
                uint8(bytes(contents[1]).length),
                bytes(contents[1]),
                uint8(bytes(contents[2]).length),
                bytes(contents[2])
            ),
            uint8(bytes(contents[3]).length),
            bytes(contents[3]),
            uint8(bytes(contents[4]).length),
            bytes(contents[4])
        ));
    }

    function packPhotochromicRecord(string memory userId, string memory profile, string memory contents, uint32 t) public pure returns (string memory) {
        return string(abi.encodePacked(
            t, // timestamp
            contents,
            uint8(bytes(userId).length),
            bytes(userId),
            uint8(bytes(profile).length),
            bytes(profile)
        ));
    }

    function concatTimestamp(bytes memory value, uint32 ts) public pure returns (bytes memory) {
        bytes4 t = bytes4(ts);
        bytes memory merged = new bytes(value.length + 4);
        for (uint i = 0; i < value.length; i++) {
            merged[i] = value[i];
        }
        for (uint i = 0; i < t.length; i++) {
            merged[value.length + i] = t[i];
        }
        return merged;
    }

    function extractTimestamp(bytes memory value) public pure returns (bytes memory, uint32) {
        if (value.length == 0) return (value, 0);
        bytes memory split = new bytes(value.length - 4);
        for (uint i = 0; i < value.length - 4; i++) {
            split[i] = value[i];
        }
        uint32 t = (uint32(uint8(value[value.length - 4])) << 24) | (uint32(uint8(value[value.length - 3])) << 16) | (uint32(uint8(value[value.length - 2])) << 8) | uint32(uint8(value[value.length - 1]));
        return (split, t);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMulticallable {
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SupportsInterface.sol";

abstract contract ResolverBase is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDynamic.sol";
import "./interfaces/INft.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DynamicNft is AccessControl, IDynamic {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public merkleRoot;
    bytes32 public constant ZEROSTATE = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address public immutable treasuryAddress;
    address private cap3Wallet;
    address public genesisContractAddress;
    address public subsContractAddress;

    uint256 public genesisPrice = 2 ether;
    uint256 public subscriptionPrice = 1 ether;
    uint256 private projectId = 1;
    uint256 public genesisSupply = 2000;
    uint256 public subscriptionSupply = 7000;
    uint256 private genesisVotingPower = 2;
    uint256 private subscriptionVotingPower = 1;
    uint256 private treasuryLimit = 5e6;

    bool public genesisStatus = true;
    bool public subscriptionStatus;
    bool public refundFlag;

    struct Genesis {
        uint256 tokenId;
        address owner;
    }

    struct Subscription {
        uint256 tokenId;
        uint256 renewalExpire;
        address owner;
        bool expired;
        bool renewed;
    }

    struct Project {
        string id;
        string description;
        address author;
        bool funded;
    }

    enum TOKEN {
        GENESIS,
        SUBSCRIPTION
    }

    /*------ Events -------*/

    event SubscriptionMintStateUpdated(bool state);
    event GenesisMintStateUpdated(bool state);
    event GenesisMinted(address to, uint256 id);
    event SubscriptionMinted(address to, uint256 id);
    event SubscriptionRenewed(address holder, uint256 tokenId);
    event ExpiredSubscription(address holder, uint256 renewalExpire, uint256 tokenId);
    event MerkleRootSet(bytes32 _merkleRoot);
    event Refunded(address owner, uint256[] tokenIds);
    event TreasuryLimitSet(uint256 newLimit, uint256 oldLimit);
    event SubscriptionBalanceUpdated(uint256 TokenSupply, uint256 tokenId);
    event ProposalApproved(string id, string _title, address author, uint256 amount);
    event ProposalFunded(string id, uint256 amount);
    event UpdatedBackendAddress(address backendAddress, string Role);
    event RefundStateUpdated(bool _state);
    event NftTransfered(address to, uint256 tokenId, bool isGenesis);

    mapping(string => Project) private proposals;
    mapping(uint256 => Genesis) public genesisHolder;
    mapping(uint256 => Subscription) public subsHolder;

    AggregatorV3Interface internal priceFeed;

    constructor(
        address _genesis,
        address _subscription,
        address _treasury,
        address _cap3Wallet,
        address _priceFeedAggregator
    ) {
        require(_genesis != address(0), "ADDRESS ZERO");
        require(_subscription != address(0), "ADDRESS ZERO");
        require(_treasury != address(0), "ADDRESS ZERO");
        require(_cap3Wallet != address(0), "ADDRESS ZERO");
        require(_priceFeedAggregator != address(0), "ADDRESS ZER0");

        subsContractAddress = _subscription;
        genesisContractAddress = _genesis;
        treasuryAddress = _treasury;
        cap3Wallet = _cap3Wallet;

        priceFeed = AggregatorV3Interface(_priceFeedAggregator);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(NFT_ROLE, _genesis);
        _setupRole(NFT_ROLE, _subscription);
    }

    /*------- State Changing Functions ------*/

    function mintGenesis(address _to, bytes32[] calldata _merkleProof, uint256 amount) public payable {

        INft GenesisNft = INft(genesisContractAddress);
        require(msg.value >= (genesisPrice * amount), "INSUFFICIENT MINTING VALUE");
        require(genesisStatus, "GENESIS MINT CURRENTLY INACTIVE");
        require(GenesisNft.totalSupply() + amount <= genesisSupply, "INSUFICIENT GENESIS STOCK");
        if (merkleRoot != ZEROSTATE){
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_to))), "INVALID MERKLE PROOF");
        } 

        for (uint256 _id = GenesisNft.currentIndex(); _id < (amount + GenesisNft.currentIndex()); _id++) {
            genesisHolder[_id] = Genesis({tokenId: _id, owner: _to});
            emit GenesisMinted(_to, _id);
        }

        GenesisNft.mint(_to, amount);
        
        (bool success, ) = treasuryAddress.call{value: msg.value}("");
        require(success, "MINT:ETH TRANSFER FAILED");

        ITreasury treasury = ITreasury(payable(treasuryAddress));
        if (GenesisNft.totalSupply() == genesisSupply) {
            treasury.moveFundsOutOfTreasury();
            genesisStatus = false;
        }

    }


    function mintSubscription(address _to, uint256 amount) public payable {
        INft SubscriptionNft = INft(subsContractAddress);
        require(msg.value >= (subscriptionPrice * amount), "INSUFFICIENT MINTING VALUE");
        require(subscriptionStatus, "SUBS MINT CURRENTLY INACTIVE");
        require(SubscriptionNft.totalSupply() + amount <= subscriptionSupply, "INSUFICIENT SUBSCRIPTION STOCK");

        for (uint256 _id = SubscriptionNft.currentIndex(); _id < (amount + SubscriptionNft.currentIndex()); _id++) {
            subsHolder[_id] = Subscription({
                tokenId: _id,
                owner: _to,
                expired: false,
                renewed: false,
                renewalExpire: 0
            });
            emit SubscriptionMinted(_to, _id);

        }

        SubscriptionNft.mint(_to, amount);
        cap3TreasuryFundShare(msg.value);
    }

    function refund(bool _state) public onlyRole(ADMIN_ROLE) {
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        string memory boolString = _state == true ? "true" : "false";
        require(refundFlag != _state, string(abi.encodePacked("Refund Flag already ", boolString)));
        refundFlag = _state;
        emit RefundStateUpdated(_state);
    }

    function claimRefund(uint256[] calldata tokenIds) public {
        INft GenesisNft = INft(genesisContractAddress);
        ITreasury treasury = ITreasury(treasuryAddress);
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        require(refundFlag == true, "REFUND NOT OPEN");
        uint256 arrayLength = tokenIds.length;
        uint256[] memory refundedTokens = new uint256[](arrayLength);

        for (uint256 i = 0; i < tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            if (GenesisNft.ownerOf(tokenId) == msg.sender){
                uint256 toRefund = genesisPrice;
                GenesisNft.burn(tokenId);
                delete (genesisHolder[tokenId]);
                treasury.payRefund(msg.sender, toRefund);
                refundedTokens[i] = tokenId;
            }
            
        }
        
        emit Refunded(msg.sender, refundedTokens);
    }

    function transferNft(address _to, uint256 _tokenId) public onlyRole(NFT_ROLE) {

        if (msg.sender == genesisContractAddress) {
            Genesis storage token = genesisHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, true);
        } else if (msg.sender == subsContractAddress) {
            Subscription storage token = subsHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, false);
        }
    }

    function subscriptionExpiry(uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) {
        Subscription storage token = subsHolder[_tokenId];
        require(token.expired == false, "CANT CALL ON ALREADY EXPIRED TOKEN");
        token.expired = true;
        if (token.renewed == true) {
            _updateSubscriptionMintBalance(_tokenId);
            token.renewalExpire = 0;
        } else token.renewalExpire = block.timestamp + 7 days;

        emit ExpiredSubscription(token.owner, token.renewalExpire, token.tokenId);
    }

    function renewSubscription(uint256 _tokenId) public payable {
        require(msg.value >= (subscriptionPrice), "INSUFFICIENT MINTING VALUE");

        Subscription storage token = subsHolder[_tokenId];
        require(token.renewalExpire > 0, "SUBSCRIPTION NOT EXPIRED");
        require(block.timestamp <= token.renewalExpire, "RENEWAL DATE HAS EXPIRED");
        require(token.renewed == false, "ALREADY RENEWED");

        cap3TreasuryFundShare(msg.value);
        token.renewed = true;
        token.expired = false;
        emit SubscriptionRenewed(msg.sender, token.tokenId);
    }

    function updateSubscriptionMintBalance(uint256 _tokenId) public onlyRole(EXECUTOR_ROLE) {
        _updateSubscriptionMintBalance(_tokenId);
    }

    function _updateSubscriptionMintBalance(uint256 _tokenId) internal {
        Subscription storage token = subsHolder[_tokenId];
        require(token.expired == true, "NON EXPIRED TOKEN");
        require(block.timestamp >= token.renewalExpire, "RENEWAL DATELINE NOT PASSED");
        unchecked {
            subscriptionSupply++;
        }
        emit SubscriptionBalanceUpdated(subscriptionSupply, _tokenId);
    }

    function addApprovedProposal(
        string memory _id,
        string memory _title,
        address _author,
        uint256 _funds
    ) public onlyRole(ADMIN_ROLE) {
        proposals[_id] = Project({id: _id, description: _title, author: _author, funded: false});
        ITreasury treasury = ITreasury(payable(treasuryAddress));
        treasury.setProjectBalance(_author, _funds);
        emit ProposalApproved(_id, _title, _author, _funds);
    }

    function fundProposal(string memory _id, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        Project memory proposal = proposals[_id];
        require(proposal.funded == false, "PROJECT HAS BEEN FUNDED");
        proposal.funded = true;
        ITreasury treasury = ITreasury(treasuryAddress);
        treasury.withdrawToProjectWallet(proposal.author, _amount);

        emit ProposalFunded(_id, _amount);
    }

    function cap3TreasuryFundShare(uint256 _amount) internal {
        uint256 dollarValueOfEth = getLatestPrice();
        uint256 limitInEth = (treasuryLimit * 10**18) / dollarValueOfEth;

        if (address(treasuryAddress).balance > limitInEth) {
            uint256 extraBalance = address(treasuryAddress).balance - limitInEth;

            ITreasury treasury = ITreasury(payable(treasuryAddress));
            treasury.payRefund(cap3Wallet, extraBalance);

            (bool success, ) = cap3Wallet.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if (address(treasuryAddress).balance == limitInEth) {
            (bool success, ) = cap3Wallet.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if ((address(treasuryAddress).balance + _amount) > limitInEth) {
            uint256 treasuryAmount = limitInEth - address(treasuryAddress).balance;
            uint256 cap3amount = _amount - treasuryAmount;

            (bool success, ) = treasuryAddress.call{value: treasuryAmount}("");
            require(success, "MINT:ETH TRANSFER FAILED");

            (success, ) = cap3Wallet.call{value: cap3amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if ((address(treasuryAddress).balance + _amount) <= limitInEth) {
            (bool success, ) = treasuryAddress.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        }
    }

    function setTreasuryLimit(uint256 _newLimit) public onlyRole(ADMIN_ROLE) {
        _setTreasuryLimit(_newLimit);
    }

    function switchGenesisMint(bool _state) public onlyRole(ADMIN_ROLE) {
        string memory boolString = _state == true ? "true" : "false";
        require(genesisStatus != _state, string(abi.encodePacked("Genesis Flag already ", boolString)));
        genesisStatus = _state;
        emit GenesisMintStateUpdated(_state);
    }

    function switchSubscriptionMint(bool _state) public onlyRole(ADMIN_ROLE) {
        string memory boolString = _state == true ? "true" : "false";
        require(subscriptionStatus != _state, string(abi.encodePacked("Subscription Flag already ", boolString)));
        subscriptionStatus = _state;
        emit SubscriptionMintStateUpdated(_state);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    function setBackendAdress(address _backendAddress) public onlyRole(ADMIN_ROLE) {
        require(_backendAddress != address(0), "ADDRESS ZERO");
        _setupRole(EXECUTOR_ROLE, _backendAddress);
        emit UpdatedBackendAddress(_backendAddress, "EXECUTOR_ROLE");
    }

    function setGenesisVotingPower(uint256 newVotingPower) public onlyRole(ADMIN_ROLE) {
        genesisVotingPower = newVotingPower;
    }

    function setAdminRole(address _adminAddress) public onlyRole(ADMIN_ROLE) {
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    function setGenesisPrice(uint256 price) public onlyRole(ADMIN_ROLE) {
        genesisPrice = price * 10**18 ;
    
    }

    function setSubscriptionPrice(uint256 price) public onlyRole(ADMIN_ROLE) {
        subscriptionPrice = price * 10**18;
    }

    function setSubscriptionVotingPower(uint256 newVotingPower) public onlyRole(ADMIN_ROLE) {
        subscriptionVotingPower = newVotingPower;
    }

    function setGenesisSupply(uint256 _newGenesisSupply) public onlyRole(ADMIN_ROLE) {
        INft GenesisNft = INft(genesisContractAddress);
        require(_newGenesisSupply >= GenesisNft.totalSupply());
        genesisSupply = _newGenesisSupply;
    }

    function setGenesisMintPublic() public onlyRole(ADMIN_ROLE) {
        merkleRoot = ZEROSTATE;
        emit MerkleRootSet(merkleRoot);
    }

    function setSubscriptionSupply(uint256 _newSubscriptionSupply) public onlyRole(ADMIN_ROLE) {
        INft SubscriptionNft = INft(subsContractAddress);
        require(_newSubscriptionSupply >= SubscriptionNft.totalSupply());
        subscriptionSupply = _newSubscriptionSupply;
    }

    /*------ View Functions -------*/
    function getGenesisSupply() public view returns (uint256) {
        return genesisSupply;
    }

    function getSubscriptionSupply() public view returns (uint256) {
        return subscriptionSupply;
    }

    function getGenesisHolder(uint256 _tokenId) public view returns (Genesis memory) {
        return genesisHolder[_tokenId];
    }

    function getSubscriptionHolder(uint256 _tokenId) public view returns (Subscription memory) {
        return subsHolder[_tokenId];
    }

    function getTreasuryLimit() public view returns (uint256) {
        return treasuryLimit;
    }

    function getCap3WalletAddress() public view returns (address) {
        return cap3Wallet;
    }

    function subscriptionHasExpired(uint256 _tokenId) public view returns (bool) {
        Subscription storage token = subsHolder[_tokenId];
        return token.expired;
    }

    function userVotingPower(address _holder) public view returns (uint256) {
        INft GenesisNft = INft(genesisContractAddress);
        uint256 votingPower = 0;
        votingPower += getValidSubscriptions(_holder) * subscriptionVotingPower;
        votingPower += GenesisNft.balanceOf(_holder) * genesisVotingPower;
        return votingPower;
    }

    function getValidSubscriptions(address _holder) public view returns (uint256) {
        INft SubscriptionNft = INft(subsContractAddress);
        uint256 subscriptionsValid = 0;
        uint256 subscriptionsIndex = 1;
        uint256 subscriptionsChecked = 0;

        while (subscriptionsChecked < SubscriptionNft.balanceOf(_holder)) {
            if (SubscriptionNft.ownerOf(subscriptionsIndex) == _holder) {
                if (!subscriptionHasExpired(subscriptionsIndex)) {
                    subscriptionsValid++;
                }
                subscriptionsChecked++;
            }
            subscriptionsIndex++;
        }

        return subscriptionsValid;
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price / 10**8);
    }

    /*------ Internal Functions -------*/

    function _setTreasuryLimit(uint256 _newLimit) internal {
        uint256 oldLimit = treasuryLimit;
        treasuryLimit = _newLimit;
        emit TreasuryLimitSet(_newLimit, oldLimit);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITreasury {
    function withdrawToProjectWallet(address projectWallet, uint256 amount) external;

    function shutdown(bool _isShutdown) external;

    function viewFundsInTreasury() external view returns (uint256);

    function payRefund(address _to, uint256 _amount) external;

    function setProjectBalance(address _projectWallet, uint256 _balance) external;

    function moveFundsOutOfTreasury() external;

    function setAdminRole(address _adminAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IDynamic {
    function renewSubscription(uint256 tokenid) external payable;

    function mintGenesis(address to, bytes32[] calldata _merkleProof, uint256 amount) external payable;

    function mintSubscription(address to, uint256 amount) external payable;

    function refund(bool state) external;

    function subscriptionExpiry(uint256 tokenId) external;

    function updateSubscriptionMintBalance(uint256 tokenId) external;

    function addApprovedProposal(
        string memory id,
        string memory title,
        address author,
        uint256 funds
    ) external;

    function transferNft(address _to, uint256 _tokenId) external;

    function fundProposal(string memory id, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "erc721a/contracts/IERC721A.sol";

interface INft is IERC721A{
    function mint(address to, uint256 amount) external;

    function burn(uint256 tokenId) external;

    function currentIndex() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
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
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}
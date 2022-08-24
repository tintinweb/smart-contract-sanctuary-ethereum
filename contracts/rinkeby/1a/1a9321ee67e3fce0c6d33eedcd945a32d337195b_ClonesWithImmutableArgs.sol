/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: AGPL-3.0-only
 
pragma solidity >=0.8.4;
 
/// @notice Modern and gas-optimized ERC-20 + EIP-2612 implementation with COMP-style governance and pausing.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract KaliDAOxToken {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------
 
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 amount
    );
 
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 amount
    );
 
    event DelegateChanged(
        address indexed delegator, 
        address indexed fromDelegate, 
        address indexed toDelegate
    );
 
    event DelegateVotesChanged(
        address indexed delegate, 
        uint256 previousBalance, 
        uint256 newBalance
    );
 
    event PauseFlipped();
 
    /// -----------------------------------------------------------------------
    /// ERRORS
    /// -----------------------------------------------------------------------
 
    error NoArrayParity();
 
    error Paused();
 
    error SignatureExpired();
 
    error NotDetermined();
 
    error InvalidSignature();
 
    error Uint32max();
 
    error Uint96max();

    /// -----------------------------------------------------------------------
    /// IMMUTABLE STORAGE
    /// -----------------------------------------------------------------------

    uint8 public constant decimals = 18;

    function INITIAL_CHAIN_ID() internal pure returns (uint256) {
        return _getArgUint256(66);
    }

    function name() public pure virtual returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(8)));
    }
 
    function symbol() public pure virtual returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(20)));
    }
 
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        virtual
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
 
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }
 
    function _getImmutableArgsOffset() internal pure virtual returns (uint256 offset) {
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC-20 STORAGE
    /// -----------------------------------------------------------------------
 
    uint256 public totalSupply;
 
    mapping(address => uint256) public balanceOf;
 
    mapping(address => mapping(address => uint256)) public allowance;
 
    /// -----------------------------------------------------------------------
    /// EIP-2612 STORAGE
    /// -----------------------------------------------------------------------

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;
 
    mapping(address => uint256) public nonces;
 
    /// -----------------------------------------------------------------------
    /// DAO STORAGE
    /// -----------------------------------------------------------------------
 
    bool public paused;
 
    mapping(address => address) internal _delegates;
 
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
 
    mapping(address => uint256) public numCheckpoints;
 
    struct Checkpoint {
        uint32 fromTimestamp;
        uint96 votes;
    }
 
    /// -----------------------------------------------------------------------
    /// INITIALIZER
    /// -----------------------------------------------------------------------
 
    function _init(
        bool paused_,
        address[] memory voters_,
        uint256[] memory shares_
    ) internal virtual {
        if (voters_.length != shares_.length) revert NoArrayParity();
       
        paused = paused_;
       
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
 
        address voter;
 
        uint256 shares;
 
        uint256 supply;
       
        for (uint256 i; i < voters_.length; ) {
            voter = voters_[i];
 
            shares = shares_[i];
 
            supply += shares;
 
            _moveDelegates(
                address(0), 
                voter, 
                shares
            );
 
            emit Transfer(
                address(0), 
                voter, 
                shares
            );
 
            // cannot realistically overflow on human timescales
            unchecked {
                balanceOf[voter] += shares;
 
                ++i;
            }
        }
 
        totalSupply = _safeCastTo96(supply);
    }
 
    /// -----------------------------------------------------------------------
    /// ERC-20 LOGIC
    /// -----------------------------------------------------------------------
 
    function approve(address spender, uint256 amount) public payable virtual returns (bool) {
        allowance[msg.sender][spender] = amount;
 
        emit Approval(
            msg.sender, 
            spender, 
            amount
        );
 
        return true;
    }
 
    function transfer(address to, uint256 amount) public payable notPaused virtual returns (bool) {
        balanceOf[msg.sender] -= amount;
 
        // cannot overflow because the sum of all user
        // balances can't exceed the max uint96 value
        unchecked {
            balanceOf[to] += amount;
        }
       
        _moveDelegates(
            delegates(msg.sender), 
            delegates(to), 
            amount
        );
 
        emit Transfer(
            msg.sender, 
            to, 
            amount
        );
 
        return true;
    }
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public payable notPaused virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max)
            allowance[from][msg.sender] -= amount;
 
        balanceOf[from] -= amount;
 
        // cannot overflow because the sum of all user
        // balances can't exceed the max uint96 value
        unchecked {
            balanceOf[to] += amount;
        }
       
        _moveDelegates(
            delegates(from), 
            delegates(to), 
            amount
        );
 
        emit Transfer(from, to, amount);
 
        return true;
    }
 
    /// -----------------------------------------------------------------------
    /// EIP-2612 LOGIC
    /// -----------------------------------------------------------------------
 
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID() ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }
 
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes(name())),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }
 
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
 
        // cannot realistically overflow on human timescales
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19\x01',
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
 
            if (recoveredAddress == address(0)) revert InvalidSignature();
 
            if (recoveredAddress != owner) revert InvalidSignature();
 
            allowance[recoveredAddress][spender] = value;
        }
 
        emit Approval(
            owner, 
            spender, 
            value
        );
    }
 
    /// -----------------------------------------------------------------------
    /// DAO LOGIC
    /// -----------------------------------------------------------------------
 
    modifier notPaused() {
        if (paused) revert Paused();
 
        _;
    }
   
    function delegates(address delegator) public view virtual returns (address) {
        address current = _delegates[delegator];
       
        return current == address(0) ? delegator : current;
    }
 
    function delegate(address delegatee) public payable virtual {
        _delegate(msg.sender, delegatee);
    }
 
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
 
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                'Delegation(address delegatee,uint256 nonce,uint256 deadline)'
                            ),
                            delegatee,
                            nonce,
                            deadline
                        )
                    )
                )
            ),
            v,
            r,
            s
        );
 
        if (recoveredAddress == address(0)) revert InvalidSignature();
       
        // cannot realistically overflow on human timescales
        unchecked {
            if (nonce != nonces[recoveredAddress]++) revert InvalidSignature();
        }
 
        _delegate(recoveredAddress, delegatee);
    }
 
    function getCurrentVotes(address account) public view virtual returns (uint96) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];
 
            return nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }
 
    function getPriorVotes(address account, uint256 timestamp) public view virtual returns (uint96) {
        if (block.timestamp <= timestamp) revert NotDetermined();
 
        uint256 nCheckpoints = numCheckpoints[account];
 
        if (nCheckpoints == 0) return 0;
       
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp)
                return checkpoints[account][nCheckpoints - 1].votes;
 
            if (checkpoints[account][0].fromTimestamp > timestamp) return 0;
 
            uint256 lower;
           
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            uint256 upper = nCheckpoints - 1;
 
            while (upper > lower) {
                // this is safe from underflow because ceil is provided
                uint256 center = upper - (upper - lower) / 2;
 
                Checkpoint memory cp = checkpoints[account][center];
 
                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }
 
        return checkpoints[account][lower].votes;
 
        }
    }
 
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
 
        _delegates[delegator] = delegatee;
 
        _moveDelegates(
            currentDelegate, 
            delegatee, 
            balanceOf[delegator]
        );
 
        emit DelegateChanged(
            delegator, 
            currentDelegate, 
            delegatee
        );
    }
 
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal virtual {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
 
                uint256 srcRepOld;
 
                // this is safe from underflow because decrement only occurs if `srcRepNum` is positive
                unchecked {
                    srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                }
 
                uint256 srcRepNew = srcRepOld - amount;
 
                _writeCheckpoint(
                    srcRep, 
                    srcRepNum, 
                    srcRepOld, 
                    srcRepNew
                );
            }
           
            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
 
                uint256 dstRepOld;
 
                // this is safe from underflow because decrement only occurs if `dstRepNum` is positive
                unchecked {
                    dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                }
 
                uint256 dstRepNew = dstRepOld + amount;
 
                _writeCheckpoint(
                    dstRep, 
                    dstRepNum, 
                    dstRepOld, 
                    dstRepNew
                );
            }
        }
    }
 
    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal virtual {
        unchecked {
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            if (nCheckpoints != 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = _safeCastTo96(newVotes);
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(_safeCastTo32(block.timestamp), _safeCastTo96(newVotes));
               
                // cannot realistically overflow on human timescales
                ++numCheckpoints[delegatee];
            }
        }
 
        emit DelegateVotesChanged(
            delegatee, 
            oldVotes, 
            newVotes
        );
    }
 
    /// -----------------------------------------------------------------------
    /// MINT/BURN LOGIC
    /// -----------------------------------------------------------------------
 
    function _mint(address to, uint256 amount) internal virtual {
        _safeCastTo96(totalSupply + amount);
 
        // cannot overflow because the sum of all user
        // balances can't exceed the max uint96 value
        unchecked {
            balanceOf[to] += amount;
        }
 
        _moveDelegates(
            address(0), 
            delegates(to), 
            amount
        );
 
        emit Transfer(
            address(0), 
            to, 
            amount
        );
    }
 
    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
 
        // cannot underflow because a user's balance
        // will never be larger than the total supply
        unchecked {
            totalSupply -= amount;
        }
 
        _moveDelegates(
            delegates(from), 
            address(0), 
            amount
        );
 
        emit Transfer(
            from, 
            address(0), 
            amount
        );
    }
   
    function burn(uint256 amount) public payable virtual {
        _burn(msg.sender, amount);
    }
 
    function burnFrom(address from, uint256 amount) public payable virtual {
        if (allowance[from][msg.sender] != type(uint256).max)
            allowance[from][msg.sender] -= amount;
 
        _burn(from, amount);
    }
 
    /// -----------------------------------------------------------------------
    /// PAUSE LOGIC
    /// -----------------------------------------------------------------------
 
    function _flipPause() internal virtual {
        paused = !paused;
 
        emit PauseFlipped();
    }
   
    /// -----------------------------------------------------------------------
    /// SAFECAST LOGIC
    /// -----------------------------------------------------------------------
   
    function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
        if (x > type(uint32).max) revert Uint32max();
 
        return uint32(x);
    }
   
    function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
        if (x > type(uint96).max) revert Uint96max();
 
        return uint96(x);
    }
}

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/Multicallable.sol)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public payable virtual returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // point `results` to start of free memory
                mstore(results, data.length) // store `data.length` into `results`
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20
                let end := shl(5, data.length)
                // copy the offsets from calldata into memory
                calldatacopy(results, data.offset, end)
                // pointer to the top of the memory (i.e., start of the free memory)
                let memPtr := add(results, end)
                end := add(results, end)

                for {} 1 {} {
                    // the offset of the current bytes in the calldata
                    let o := add(data.offset, mload(results))
                    
                    // copy the current bytes from calldata to the memory
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // the offset of the current bytes' bytes
                        calldataload(o) // the length of the current bytes
                    )
                    
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // bubble up the revert if the delegatecall reverts
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    
                    // append the current `memPtr` into `results`
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // append the `returndatasize()`, and the return data
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)

                    if iszero(lt(results, end)) { break }
                }
                
                // restore `results` and allocate memory for it
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

/// @notice Contract that enables NFT receipt.
abstract contract NFTreceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        if (status == ENTERED) revert Reentrancy();

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

/// @notice Kali DAO extension interface.
interface IKaliDAOxExtension {
    function setExtension(bytes calldata extensionData) external payable;
}

/// @notice Simple gas-optimized Kali DAO core module.
contract KaliDAOx is KaliDAOxToken, Multicallable, NFTreceiver, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// EVENTS
    /// -----------------------------------------------------------------------

    event NewProposal(
        address indexed proposer, 
        uint256 proposal, 
        ProposalType proposalType, 
        bytes32 description, 
        address[] accounts, 
        uint256[] amounts, 
        bytes[] payloads,
        uint32 creationTime,
        bool selfSponsor
    );

    event ProposalCancelled(address indexed proposer, uint256 proposal);

    event ProposalSponsored(address indexed sponsor, uint256 proposal);
    
    event VoteCast(
        address indexed voter, 
        uint256 proposal, 
        bool approve,
        uint96 weight
    );

    event ProposalProcessed(uint256 proposal, bool didProposalPass);

    event ExtensionSet(address extension, bool set);

    event URIset(string daoURI);

    event GovSettingsUpdated(
        uint64 votingPeriod, 
        uint64 gracePeriod, 
        uint64 quorum, 
        uint64 supermajority
    );

    /// -----------------------------------------------------------------------
    /// ERRORS
    /// -----------------------------------------------------------------------

    error Initialized();

    error PeriodBounds();

    error QuorumMax();

    error SupermajorityBounds();

    error InitCallFail();

    error TypeBounds();

    error NotProposer();

    error Sponsored();

    error NotMember();

    error NotCurrentProposal();

    error AlreadyVoted();

    error NotVoteable();

    error VotingNotEnded();

    error PrevNotProcessed();

    error NotExtension();

    /// -----------------------------------------------------------------------
    /// DAO STORAGE/LOGIC
    /// -----------------------------------------------------------------------

    string public daoURI;

    uint256 internal currentSponsoredProposal;
    
    uint256 public proposalCount;

    uint64 public votingPeriod;

    uint64 public gracePeriod;

    uint64 public quorum; // 1-100

    uint64 public supermajority; // 1-100
    
    mapping(address => bool) public extensions;

    mapping(uint256 => Proposal) public proposals;

    mapping(uint256 => ProposalState) public proposalStates;

    mapping(ProposalType => VoteType) public proposalVoteTypes;
    
    mapping(uint256 => mapping(address => bool)) public voted;

    mapping(address => uint256) public lastYesVote;

    enum ProposalType {
        MINT, // add membership
        BURN, // revoke membership
        CALL, // call contracts
        VPERIOD, // set `votingPeriod`
        GPERIOD, // set `gracePeriod`
        QUORUM, // set `quorum`
        SUPERMAJORITY, // set `supermajority`
        TYPE, // set `VoteType` to `ProposalType`
        PAUSE, // flip membership transferability
        EXTENSION, // flip `extensions` whitelisting
        ESCAPE, // delete pending proposal in case of revert
        DOCS // amend org docs
    }

    enum VoteType {
        SIMPLE_MAJORITY,
        SIMPLE_MAJORITY_QUORUM_REQUIRED,
        SUPERMAJORITY,
        SUPERMAJORITY_QUORUM_REQUIRED
    }

    struct Proposal {
        uint256 prevProposal;
        bytes32 proposalHash;
        address proposer;
        uint32 creationTime;
        uint96 yesVotes;
        uint96 noVotes;
    }

    struct ProposalState {
        bool passed;
        bool processed;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC-165 Interface ID for ERC-165
            interfaceId == 0x150b7a02 || // ERC-165 Interface ID for ERC721TokenReceiver
            interfaceId == 0x4e2312e0; // ERC-165 Interface ID for ERC1155TokenReceiver
    }

    /// -----------------------------------------------------------------------
    /// INITIALIZER
    /// -----------------------------------------------------------------------

    function init(
        string calldata daoURI_,
        bool paused_,
        address[] calldata extensions_,
        bytes[] calldata extensionsData_,
        address[] calldata voters_,
        uint256[] calldata shares_,
        uint64[16] calldata govSettings_
    ) public payable virtual {
        if (extensions_.length != extensionsData_.length) revert NoArrayParity();

        if (votingPeriod != 0) revert Initialized();

        if (govSettings_[0] == 0) revert PeriodBounds(); 
        
        if (govSettings_[0] > 365 days) revert PeriodBounds();

        if (govSettings_[1] > 365 days) revert PeriodBounds();

        if (govSettings_[2] > 100) revert QuorumMax();

        if (govSettings_[3] <= 51) revert SupermajorityBounds();
        
        if (govSettings_[3] > 100) revert SupermajorityBounds();

        KaliDAOxToken._init(
            paused_, 
            voters_, 
            shares_
        );

        if (extensions_.length != 0) {
            // cannot realistically overflow on human timescales
            unchecked {
                for (uint256 i; i < extensions_.length; i++) {
                    extensions[extensions_[i]] = true;

                    if (extensionsData_[i].length > 9) {
                        (bool success, ) = extensions_[i].call(extensionsData_[i]);

                        if (!success) revert InitCallFail();
                    }
                }
            }
        }

        daoURI = daoURI_;
        
        votingPeriod = govSettings_[0];

        gracePeriod = govSettings_[1];
        
        quorum = govSettings_[2];
        
        supermajority = govSettings_[3];

        // set initial vote types
        proposalVoteTypes[ProposalType.MINT] = VoteType(govSettings_[4]);

        proposalVoteTypes[ProposalType.BURN] = VoteType(govSettings_[5]);

        proposalVoteTypes[ProposalType.CALL] = VoteType(govSettings_[6]);

        proposalVoteTypes[ProposalType.VPERIOD] = VoteType(govSettings_[7]);

        proposalVoteTypes[ProposalType.GPERIOD] = VoteType(govSettings_[8]);
        
        proposalVoteTypes[ProposalType.QUORUM] = VoteType(govSettings_[9]);
        
        proposalVoteTypes[ProposalType.SUPERMAJORITY] = VoteType(govSettings_[10]);

        proposalVoteTypes[ProposalType.TYPE] = VoteType(govSettings_[11]);
        
        proposalVoteTypes[ProposalType.PAUSE] = VoteType(govSettings_[12]);
        
        proposalVoteTypes[ProposalType.EXTENSION] = VoteType(govSettings_[13]);

        proposalVoteTypes[ProposalType.ESCAPE] = VoteType(govSettings_[14]);

        proposalVoteTypes[ProposalType.DOCS] = VoteType(govSettings_[15]);
    }

    /// -----------------------------------------------------------------------
    /// PROPOSAL LOGIC
    /// -----------------------------------------------------------------------

    function propose(
        ProposalType proposalType,
        bytes32 description,
        address[] calldata accounts, // member(s) being added/kicked; account(s) receiving payload
        uint256[] calldata amounts, // value(s) to be minted/burned/spent; gov setting [0]
        bytes[] calldata payloads // data for CALL proposals
    ) public payable virtual returns (uint256 proposal) {
        if (accounts.length != amounts.length) revert NoArrayParity();

        if (amounts.length != payloads.length) revert NoArrayParity();
        
        if (proposalType == ProposalType.VPERIOD) if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

        if (proposalType == ProposalType.GPERIOD) if (amounts[0] > 365 days) revert PeriodBounds();
        
        if (proposalType == ProposalType.QUORUM) if (amounts[0] > 100) revert QuorumMax();
        
        if (proposalType == ProposalType.SUPERMAJORITY) if (amounts[0] <= 51 || amounts[0] > 100) revert SupermajorityBounds();

        if (proposalType == ProposalType.TYPE) if (amounts[0] > 11 || amounts[1] > 3 || amounts.length != 2) revert TypeBounds();

        bool selfSponsor;

        // if member or extension is making proposal, include sponsorship
        if (balanceOf[msg.sender] != 0 || extensions[msg.sender]) selfSponsor = true;

        // cannot realistically overflow on human timescales
        unchecked {
            proposal = ++proposalCount;
        }

        bytes32 proposalHash = keccak256(
            abi.encode(
                proposalType,
                description,
                accounts,
                amounts,
                payloads
            )
        );

        uint32 creationTime = selfSponsor ? _safeCastTo32(block.timestamp) : 0;

        proposals[proposal] = Proposal({
            prevProposal: selfSponsor ? currentSponsoredProposal : 0,
            proposalHash: proposalHash,
            proposer: msg.sender,
            creationTime: creationTime,
            yesVotes: 0,
            noVotes: 0
        });

        if (selfSponsor) currentSponsoredProposal = proposal;

        emit NewProposal(
            msg.sender, 
            proposal, 
            proposalType, 
            description,
            accounts, 
            amounts, 
            payloads,
            creationTime,
            selfSponsor
        );
    }

    function cancelProposal(uint256 proposal) public payable virtual {
        Proposal storage prop = proposals[proposal];

        if (msg.sender != prop.proposer && !extensions[msg.sender]) revert NotProposer();

        if (prop.creationTime != 0) revert Sponsored();

        delete proposals[proposal];

        emit ProposalCancelled(msg.sender, proposal);
    }

    function sponsorProposal(uint256 proposal) public payable virtual {
        Proposal storage prop = proposals[proposal];

        if (balanceOf[msg.sender] == 0 && !extensions[msg.sender]) revert NotMember();

        if (prop.proposer == address(0)) revert NotCurrentProposal();

        if (prop.creationTime != 0) revert Sponsored();

        prop.prevProposal = currentSponsoredProposal;

        currentSponsoredProposal = proposal;

        prop.creationTime = _safeCastTo32(block.timestamp);

        emit ProposalSponsored(msg.sender, proposal);
    } 

    function vote(uint256 proposal, bool approve) public payable virtual {
        _vote(
            msg.sender, 
            proposal, 
            approve
        );
    }
    
    function voteBySig(
        uint256 proposal, 
        bool approve, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public payable virtual {
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                'SignVote(uint256 proposal,bool approve)'
                            ),
                            proposal,
                            approve
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        if (recoveredAddress == address(0)) revert InvalidSignature();
        
        _vote(
            recoveredAddress, 
            proposal, 
            approve
        );
    }
    
    function _vote(
        address signer, 
        uint256 proposal, 
        bool approve
    ) internal virtual {
        Proposal storage prop = proposals[proposal];

        if (voted[proposal][signer]) revert AlreadyVoted();
        
        // this is safe from overflow because `votingPeriod` is capped so it will not combine
        // with unix time to exceed the max uint256 value
        unchecked {
            if (block.timestamp > prop.creationTime + votingPeriod) revert NotVoteable();
        }

        uint96 weight = getPriorVotes(signer, prop.creationTime);
        
        // this is safe from overflow because `yesVotes` and `noVotes` are capped by `totalSupply`
        // which is checked for overflow in `KaliDAOtoken` contract
        unchecked { 
            if (approve) {
                prop.yesVotes += weight;

                lastYesVote[signer] = proposal;
            } else {
                prop.noVotes += weight;
            }
        }
        
        voted[proposal][signer] = true;
        
        emit VoteCast(
            signer, 
            proposal, 
            approve, 
            weight
        );
    }

    function processProposal(
        uint256 proposal,
        ProposalType proposalType,
        bytes32 description,
        address[] calldata accounts, 
        uint256[] calldata amounts, 
        bytes[] calldata payloads
    ) public payable nonReentrant virtual returns (bool didProposalPass, bytes[] memory results) {
        Proposal storage prop = proposals[proposal];

        { // scope to avoid stack too deep error
        VoteType voteType = proposalVoteTypes[proposalType];

        if (prop.creationTime == 0) revert NotCurrentProposal();

        bytes32 proposalHash = keccak256(
            abi.encode(
                proposalType,
                description,
                accounts,
                amounts,
                payloads
            )
        );

        if (proposalHash != prop.proposalHash) revert NotCurrentProposal();

        // skip previous proposal processing requirement in case of escape hatch
        if (proposalType != ProposalType.ESCAPE) 
            if (proposals[prop.prevProposal].creationTime != 0) revert PrevNotProcessed();

        didProposalPass = _countVotes(voteType, prop.yesVotes, prop.noVotes);
        } // end scope
        
        // this is safe from overflow because `votingPeriod` and `gracePeriod` are capped so they will not combine
        // with unix time to exceed the max uint256 value
        unchecked {
            if (!didProposalPass && gracePeriod != 0) {
                if (block.timestamp <= prop.creationTime + (
                    votingPeriod - (
                        block.timestamp - (prop.creationTime + votingPeriod))
                    ) 
                    + gracePeriod
                ) revert VotingNotEnded();
            }
        }
 
        if (didProposalPass) {
            // cannot realistically overflow on human timescales
            unchecked {
                if (proposalType == ProposalType.MINT) {
                    for (uint256 i; i < accounts.length; i++) {
                        _mint(accounts[i], amounts[i]);
                    }
                } else if (proposalType == ProposalType.BURN) { 
                    for (uint256 i; i < accounts.length; i++) {
                        _burn(accounts[i], amounts[i]);
                    }
                } else if (proposalType == ProposalType.CALL) {
                    for (uint256 i; i < accounts.length; i++) {
                        results = new bytes[](accounts.length);
                        
                        (, bytes memory result) = accounts[i].call{value: amounts[i]}
                            (payloads[i]);
                        
                        results[i] = result;
                    }
                } else if (proposalType == ProposalType.VPERIOD) {
                    if (amounts[0] != 0) votingPeriod = uint64(amounts[0]);
                } else if (proposalType == ProposalType.GPERIOD) {
                    if (amounts[0] != 0) gracePeriod = uint64(amounts[0]);
                } else if (proposalType == ProposalType.QUORUM) {
                    if (amounts[0] != 0) quorum = uint64(amounts[0]);
                } else if (proposalType == ProposalType.SUPERMAJORITY) {
                    if (amounts[0] != 0) supermajority = uint64(amounts[0]);
                } else if (proposalType == ProposalType.TYPE) {
                    proposalVoteTypes[ProposalType(amounts[0])] = VoteType(amounts[1]);
                } else if (proposalType == ProposalType.PAUSE) {
                    _flipPause();
                } else if (proposalType == ProposalType.EXTENSION) {
                    for (uint256 i; i < accounts.length; i++) {
                        if (amounts[i] != 0) 
                            extensions[accounts[i]] = !extensions[accounts[i]];
                    
                        if (payloads[i].length > 9) IKaliDAOxExtension(accounts[i])
                            .setExtension(payloads[i]);
                    }
                } else if (proposalType == ProposalType.ESCAPE) {
                    delete proposals[amounts[0]];
                } else if (proposalType == ProposalType.DOCS) {
                    daoURI = string(abi.encodePacked(description));
                }

                proposalStates[proposal].passed = true;
            }
        }

        delete proposals[proposal];

        proposalStates[proposal].processed = true;

        emit ProposalProcessed(proposal, didProposalPass);
    }

    function _countVotes(
        VoteType voteType,
        uint96 yesVotes,
        uint96 noVotes
    ) internal view virtual returns (bool didProposalPass) {
        // fail proposal if no participation
        if (yesVotes == 0 && noVotes == 0) return false;

        // rule out any failed quorums
        if (voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            // this is safe from overflow because `yesVotes` and `noVotes` 
            // supply are checked in `KaliDAOtoken` contract
            unchecked {
                if ((yesVotes + noVotes) < ((totalSupply * quorum) / 100)) return false;
            }
        }
        
        // simple majority check
        if (voteType == VoteType.SIMPLE_MAJORITY || voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED) {
            if (yesVotes > noVotes) return true;
        // supermajority check
        } else {
            // example: 7 yes, 2 no, supermajority = 66
            // ((7+2) * 66) / 100 = 5.94; 7 yes will pass ~~
            // this is safe from overflow because `yesVotes` and `noVotes` 
            // supply are checked in `KaliDAOtoken` contract
            unchecked {
                if (yesVotes >= ((yesVotes + noVotes) * supermajority) / 100) return true;
            }
        }
    }
    
    /// -----------------------------------------------------------------------
    /// EXTENSION LOGIC
    /// -----------------------------------------------------------------------

    modifier onlyExtension {
        if (!extensions[msg.sender]) revert NotExtension();

        _;
    }

    function mintShares(address to, uint256 amount) public payable onlyExtension virtual {
        _mint(to, amount);
    }

    function burnShares(address from, uint256 amount) public payable onlyExtension virtual {
        _burn(from, amount);
    }

    function relay(
        address account,
        uint256 amount,
        bytes calldata payload
    ) public payable onlyExtension virtual returns (bool success, bytes memory result) {
        (success, result) = account.call{value: amount}(payload);
    }

    function setExtension(address extension, bool set) public payable onlyExtension virtual {
        extensions[extension] = set;

        emit ExtensionSet(extension, set);
    }

    function setURI(string calldata daoURI_) public payable onlyExtension virtual {
        daoURI = daoURI_;

        emit URIset(daoURI_);
    }

    function updateGovSettings(
        uint64 votingPeriod_,
        uint64 gracePeriod_,
        uint64 quorum_,
        uint64 supermajority_
    ) public payable onlyExtension virtual {
        if (votingPeriod_ != 0) votingPeriod = votingPeriod_;

        if (gracePeriod_ != 0) gracePeriod = gracePeriod_;

        if (quorum_ != 0) quorum = quorum_;

        if (supermajority_ != 0) supermajority = supermajority_;

        emit GovSettingsUpdated(
            votingPeriod_, 
            gracePeriod_, 
            quorum_, 
            supermajority_
        );
    }
}

/// @notice Enables creating clone contracts with immutable arguments.
/// @author Modified from wighawag, zefram.eth, Saw-mon & Natalie, [email protected]
/// (https://github.com/wighawag/clones-with-immutable-args/blob/master/src/ClonesWithImmutableArgs.sol)
library ClonesWithImmutableArgs {
    error Create2Failed();

    uint256 private constant FREE_MEMORY_POINTER_SLOT = 0x40;
    uint256 private constant BOOTSTRAP_LENGTH = 0x6f;
    uint256 private constant RUNTIME_BASE = 0x65; // BOOTSTRAP_LENGTH - 10 bytes
    uint256 private constant ONE_WORD = 0x20;
    // = keccak256("ReceiveETH(uint256)")
    uint256 private constant RECEIVE_EVENT_SIG =
        0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff;

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function cloneCreationCode(address implementation, bytes memory data)
        internal
        pure
        returns (uint256 ptr, uint256 creationSize)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        assembly {
            let extraLength := add(mload(data), 2) // +2 bytes for telling how much data there is appended to the call
            creationSize := add(extraLength, BOOTSTRAP_LENGTH)
            let runSize := sub(creationSize, 0x0a)

            // free memory pointer
            ptr := mload(FREE_MEMORY_POINTER_SLOT)

            mstore(
                ptr,
                or(
                    hex"6100003d81600a3d39f336602f57343d527f", // 18 bytes
                    shl(0xe8, runSize)
                )
            )

            mstore(
                   add(ptr, 0x12), // 0x0 + 0x12
                RECEIVE_EVENT_SIG // 32 bytes
            )

            mstore(
                   add(ptr, 0x32), // 0x12 + 0x20
                or(
                    hex"60203da13d3df35b363d3d373d3d3d3d610000806000363936013d73", // 28 bytes
                    or(shl(0x68, extraLength), shl(0x50, RUNTIME_BASE))
                )
            )

            mstore(
                   add(ptr, 0x4e), // 0x32 + 0x1c
                shl(0x60, implementation) // 20 bytes
            )

            mstore(
                   add(ptr, 0x62), // 0x4e + 0x14
                hex"5af43d3d93803e606357fd5bf3" // 13 bytes
            )

            let counter := mload(data)
            let copyPtr := add(ptr, BOOTSTRAP_LENGTH)
            let dataPtr := add(data, ONE_WORD)

            for {} true {} {
                if lt(counter, ONE_WORD) { break }

                mstore(copyPtr, mload(dataPtr))

                copyPtr := add(copyPtr, ONE_WORD)
                dataPtr := add(dataPtr, ONE_WORD)

                counter := sub(counter, ONE_WORD)
            }

            let mask := shl(mul(0x8, sub(ONE_WORD, counter)), not(0))

            mstore(copyPtr, and(mload(dataPtr), mask))
            copyPtr := add(copyPtr, counter)
            mstore(copyPtr, shl(0xf0, extraLength))

            // update free memory pointer
            mstore(FREE_MEMORY_POINTER_SLOT, add(ptr, creationSize))
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        assembly {
            instance := create2(0, creationPtr, creationSize, salt)
        }
        
        // if create2 failed, the instance address won't be set
        if (instance == address(0)) {
            revert Create2Failed();
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone
    /// @return exists Whether the clone already exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted, bool exists) {
        (uint256 creationPtr, uint256 creationSize) = cloneCreationCode(
            implementation,
            data
        );

        bytes32 creationHash;

        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        predicted = 
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff), 
                                address(this), 
                                salt, 
                                creationHash
                            )
                        )
                    )
                )
            );

        exists = predicted.code.length != 0;
    }
}

/// @notice Factory to deploy Kali DAO.
contract KaliDAOxFactory is Multicallable {
    using ClonesWithImmutableArgs for address;

    event DAOdeployed(
        bytes32 name, 
        bytes32 symbol, 
        string daoURI, 
        bool paused, 
        address[] extensions, 
        bytes[] extensionsData,
        address[] voters,
        uint256[] shares,
        uint64[16] govSettings
    );

    error NullDeploy();

    KaliDAOx internal immutable kaliMaster;

    constructor(KaliDAOx kaliMaster_) payable {
        kaliMaster = kaliMaster_;
    }

    function determineKaliDAO(bytes32 name_, bytes32 symbol_)
        public
        view
        virtual
        returns (address kaliDAO, bool deployed)
    {
        (kaliDAO, deployed) = address(kaliMaster).predictDeterministicAddress(
            name_,
            abi.encodePacked(
                name_, 
                symbol_, 
                block.chainid
            )
        );
    }
    
    function deployKaliDAO(
        bytes32 name_,
        bytes32 symbol_,
        string memory daoURI_,
        bool paused_,
        address[] memory extensions_,
        bytes[] calldata extensionsData_,
        address[] calldata voters_,
        uint256[] calldata shares_,
        uint64[16] calldata govSettings_
    ) public payable virtual {
        KaliDAOx kaliDAO = KaliDAOx(
            address(kaliMaster).clone(
                name_,
                abi.encodePacked(
                    name_, 
                    symbol_, 
                    block.chainid
                )
            )
        );
        
        kaliDAO.init{value: msg.value}(
            daoURI_,
            paused_, 
            extensions_,
            extensionsData_,
            voters_, 
            shares_,  
            govSettings_
        );

        emit DAOdeployed(
            name_, 
            symbol_, 
            daoURI_, 
            paused_, 
            extensions_, 
            extensionsData_, 
            voters_, 
            shares_, 
            govSettings_
        );
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice Modern and gas-optimized ERC-20 + EIP-2612 implementation with COMP-style governance and pausing.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol)
/// License-Identifier: AGPL-3.0-only
abstract contract KaliDAOtoken {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    event PauseFlipped(bool paused);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NoArrayParity();

    error Paused();

    error SignatureExpired();

    error NullAddress();

    error InvalidNonce();

    error NotDetermined();

    error InvalidSignature();

    error Uint32max();

    error Uint96max();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                            ERC-20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

    uint256 internal INITIAL_CHAIN_ID;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                            DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    bool public paused;

    bytes32 public constant DELEGATION_TYPEHASH = 
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 deadline)');

    mapping(address => address) internal _delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint32 fromTimestamp;
        uint96 votes;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function _init(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] memory voters_,
        uint256[] memory shares_
    ) internal virtual {
        if (voters_.length != shares_.length) revert NoArrayParity();

        name = name_;
        
        symbol = symbol_;
        
        paused = paused_;

        INITIAL_CHAIN_ID = block.chainid;
        
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < voters_.length; i++) {
                _mint(voters_[i], shares_[i]);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public payable virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public payable notPaused virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }
        
        _moveDelegates(delegates(msg.sender), delegates(to), amount);

        emit Transfer(msg.sender, to, amount);

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
        // balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }
        
        _moveDelegates(delegates(from), delegates(to), amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/
    
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSignature();

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes(name)),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                            DAO LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier notPaused() {
        if (paused) revert Paused();

        _;
    }
    
    function delegates(address delegator) public view virtual returns (address) {
        address current = _delegates[delegator];
        
        return current == address(0) ? delegator : current;
    }

    function getCurrentVotes(address account) public view virtual returns (uint256) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            return nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
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

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

        address signatory = ecrecover(digest, v, r, s);

        if (signatory == address(0)) revert NullAddress();
        
        // cannot realistically overflow on human timescales
        unchecked {
            if (nonce != nonces[signatory]++) revert InvalidNonce();
        }

        _delegate(signatory, delegatee);
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
                // this is safe from underflow because `upper` ceiling is provided
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

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(
        address srcRep, 
        address dstRep, 
        uint256 amount
    ) internal virtual {
        if (srcRep != dstRep && amount != 0) 
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                
                uint256 srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            
            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];

                uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
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
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(address(0), delegates(to), amount);

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // cannot underflow because a user's balance
        // will never be larger than the total supply
        unchecked {
            totalSupply -= amount;
        }

        _moveDelegates(delegates(from), address(0), amount);

        emit Transfer(from, address(0), amount);
    }
    
    function burn(uint256 amount) public payable virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public payable virtual {
        if (allowance[from][msg.sender] != type(uint256).max) 
            allowance[from][msg.sender] -= amount;

        _burn(from, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _flipPause() internal virtual {
        paused = !paused;

        emit PauseFlipped(paused);
    }
    
    /*///////////////////////////////////////////////////////////////
                            SAFECAST LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
        if (x > type(uint32).max) revert Uint32max();

        return uint32(x);
    }
    
    function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
        if (x > type(uint96).max) revert Uint96max();

        return uint96(x);
    }
}

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public payable virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();
                    
                    assembly {
                        result := add(result, 0x04)
                    }
                    
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

/// @notice Helper utility for NFT 'safe' transfers.
abstract contract NFThelper {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0x150b7a02; // 'onERC721Received(address,address,uint256,bytes)'
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0xf23a6e61; // 'onERC1155Received(address,address,uint256,uint256,bytes)'
    }
    
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 sig) {
        sig = 0xbc197c81; // 'onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)'
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

/// @notice Kali DAO membership extension interface.
interface IKaliDAOextension {
    function setExtension(bytes calldata extensionData) external;

    function callExtension(
        address account, 
        uint256 amount, 
        bytes calldata extensionData
    ) external payable returns (bool mint, uint256 amountOut);
}

/// @notice Simple gas-optimized Kali DAO core module.
contract KaliDAO is KaliDAOtoken, Multicall, NFThelper, ReentrancyGuard {

    uint256 public count;
    
    address public recoveredAddress;
    
    bytes32 public constant VOTE_HASH = 
        keccak256('SignVote(address signer,uint256 proposal,bool approve)');

    
    function voteBySig(
        address signer, 
        uint256 proposal, 
        bool approve, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) public payable nonReentrant virtual {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            VOTE_HASH,
                            signer,
                            proposal,
                            approve
                        )
                    )
                )
            );
            
        recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) || recoveredAddress == signer, "Invalid Signature");
        
        unchecked {
            count++;
        }
    }
}
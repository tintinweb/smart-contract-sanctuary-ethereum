// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
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
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
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

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { ERC721 } from "@rari-capital/solmate/src/tokens/ERC721.sol";
import { Transactor } from "./Transactor.sol";

/**
 * @title AssetReceiver
 * @notice AssetReceiver is a minimal contract for receiving funds assets in the form of either
 * ETH, ERC20 tokens, or ERC721 tokens. Only the contract owner may withdraw the assets.
 */
contract AssetReceiver is Transactor {
    /**
     * @notice Emitted when ETH is received by this address.
     *
     * @param from   Address that sent ETH to this contract.
     * @param amount Amount of ETH received.
     */
    event ReceivedETH(address indexed from, uint256 amount);

    /**
     * @notice Emitted when ETH is withdrawn from this address.
     *
     * @param withdrawer Address that triggered the withdrawal.
     * @param recipient  Address that received the withdrawal.
     * @param amount     ETH amount withdrawn.
     */
    event WithdrewETH(address indexed withdrawer, address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when ERC20 tokens are withdrawn from this address.
     *
     * @param withdrawer Address that triggered the withdrawal.
     * @param recipient  Address that received the withdrawal.
     * @param asset      Address of the token being withdrawn.
     * @param amount     ERC20 amount withdrawn.
     */
    event WithdrewERC20(
        address indexed withdrawer,
        address indexed recipient,
        address indexed asset,
        uint256 amount
    );

    /**
     * @notice Emitted when ERC20 tokens are withdrawn from this address.
     *
     * @param withdrawer Address that triggered the withdrawal.
     * @param recipient  Address that received the withdrawal.
     * @param asset      Address of the token being withdrawn.
     * @param id         Token ID being withdrawn.
     */
    event WithdrewERC721(
        address indexed withdrawer,
        address indexed recipient,
        address indexed asset,
        uint256 id
    );

    /**
     * @param _owner Initial contract owner.
     */
    constructor(address _owner) Transactor(_owner) {}

    /**
     * @notice Make sure we can receive ETH.
     */
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    /**
     * @notice Withdraws full ETH balance to the recipient.
     *
     * @param _to Address to receive the ETH balance.
     */
    function withdrawETH(address payable _to) external onlyOwner {
        withdrawETH(_to, address(this).balance);
    }

    /**
     * @notice Withdraws partial ETH balance to the recipient.
     *
     * @param _to     Address to receive the ETH balance.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdrawETH(address payable _to, uint256 _amount) public onlyOwner {
        // slither-disable-next-line reentrancy-unlimited-gas
        (bool success, ) = _to.call{ value: _amount }("");
        emit WithdrewETH(msg.sender, _to, _amount);
    }

    /**
     * @notice Withdraws full ERC20 balance to the recipient.
     *
     * @param _asset ERC20 token to withdraw.
     * @param _to    Address to receive the ERC20 balance.
     */
    function withdrawERC20(ERC20 _asset, address _to) external onlyOwner {
        withdrawERC20(_asset, _to, _asset.balanceOf(address(this)));
    }

    /**
     * @notice Withdraws partial ERC20 balance to the recipient.
     *
     * @param _asset  ERC20 token to withdraw.
     * @param _to     Address to receive the ERC20 balance.
     * @param _amount Amount of ERC20 to withdraw.
     */
    function withdrawERC20(
        ERC20 _asset,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        // slither-disable-next-line unchecked-transfer
        _asset.transfer(_to, _amount);
        // slither-disable-next-line reentrancy-events
        emit WithdrewERC20(msg.sender, _to, address(_asset), _amount);
    }

    /**
     * @notice Withdraws ERC721 token to the recipient.
     *
     * @param _asset ERC721 token to withdraw.
     * @param _to    Address to receive the ERC721 token.
     * @param _id    Token ID of the ERC721 token to withdraw.
     */
    function withdrawERC721(
        ERC721 _asset,
        address _to,
        uint256 _id
    ) external onlyOwner {
        _asset.transferFrom(address(this), _to, _id);
        // slither-disable-next-line reentrancy-events
        emit WithdrewERC721(msg.sender, _to, address(_asset), _id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Owned } from "@rari-capital/solmate/src/auth/Owned.sol";

/**
 * @title Transactor
 * @notice Transactor is a minimal contract that can send transactions.
 */
contract Transactor is Owned {
    /**
     * @param _owner Initial contract owner.
     */
    constructor(address _owner) Owned(_owner) {}

    /**
     * Sends a CALL to a target address.
     *
     * @param _target Address to call.
     * @param _data   Data to send with the call.
     * @param _value  ETH value to send with the call.
     *
     * @return Boolean success value.
     * @return Bytes data returned by the call.
     */
    function CALL(
        address _target,
        bytes memory _data,
        uint256 _value
    ) external payable onlyOwner returns (bool, bytes memory) {
        return _target.call{ value: _value }(_data);
    }

    /**
     * Sends a DELEGATECALL to a target address.
     *
     * @param _target Address to call.
     * @param _data   Data to send with the call.
     *
     * @return Boolean success value.
     * @return Bytes data returned by the call.
     */
    function DELEGATECALL(address _target, bytes memory _data)
        external
        payable
        onlyOwner
        returns (bool, bytes memory)
    {
        // slither-disable-next-line controlled-delegatecall
        return _target.delegatecall(_data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { AssetReceiver } from "../AssetReceiver.sol";
import { IDripCheck } from "./IDripCheck.sol";

/**
 * @title Drippie
 * @notice Drippie is a system for managing automated contract interactions. A specific interaction
 *         is called a "drip" and can be executed according to some condition (called a dripcheck)
 *         and an execution interval. Drips cannot be executed faster than the execution interval.
 *         Drips can trigger arbitrary contract calls where the calling contract is this contract
 *         address. Drips can also send ETH value, which makes them ideal for keeping addresses
 *         sufficiently funded with ETH. Drippie is designed to be connected with smart contract
 *         automation services so that drips can be executed automatically. However, Drippie is
 *         specifically designed to be separated from these services so that trust assumptions are
 *         better compartmentalized.
 */
contract Drippie is AssetReceiver {
    /**
     * @notice Enum representing different status options for a given drip.
     *
     * @custom:value NONE     Drip does not exist.
     * @custom:value PAUSED   Drip is paused and cannot be executed until reactivated.
     * @custom:value ACTIVE   Drip is active and can be executed.
     * @custom:value ARCHIVED Drip is archived and can no longer be executed or reactivated.
     */
    enum DripStatus {
        NONE,
        PAUSED,
        ACTIVE,
        ARCHIVED
    }

    /**
     * @notice Represents a drip action.
     */
    struct DripAction {
        address payable target;
        bytes data;
        uint256 value;
    }

    /**
     * @notice Represents the configuration for a given drip.
     */
    struct DripConfig {
        bool reentrant;
        uint256 interval;
        IDripCheck dripcheck;
        bytes checkparams;
        DripAction[] actions;
    }

    /**
     * @notice Represents the state of an active drip.
     */
    struct DripState {
        DripStatus status;
        DripConfig config;
        uint256 last;
        uint256 count;
    }

    /**
     * @notice Emitted when a new drip is created.
     *
     * @param nameref Indexed name parameter (hashed).
     * @param name    Unindexed name parameter (unhashed).
     * @param config  Config for the created drip.
     */
    event DripCreated(
        // Emit name twice because indexed version is hashed.
        string indexed nameref,
        string name,
        DripConfig config
    );

    /**
     * @notice Emitted when a drip status is updated.
     *
     * @param nameref Indexed name parameter (hashed).
     * @param name    Unindexed name parameter (unhashed).
     * @param status  New drip status.
     */
    event DripStatusUpdated(
        // Emit name twice because indexed version is hashed.
        string indexed nameref,
        string name,
        DripStatus status
    );

    /**
     * @notice Emitted when a drip is executed.
     *
     * @param nameref   Indexed name parameter (hashed).
     * @param name      Unindexed name parameter (unhashed).
     * @param executor  Address that executed the drip.
     * @param timestamp Time when the drip was executed.
     */
    event DripExecuted(
        // Emit name twice because indexed version is hashed.
        string indexed nameref,
        string name,
        address executor,
        uint256 timestamp
    );

    /**
     * @notice Maps from drip names to drip states.
     */
    mapping(string => DripState) public drips;

    /**
     * @param _owner Initial contract owner.
     */
    constructor(address _owner) AssetReceiver(_owner) {}

    /**
     * @notice Creates a new drip with the given name and configuration. Once created, drips cannot
     *         be modified in any way (this is a security measure). If you want to update a drip,
     *         simply pause (and potentially archive) the existing drip and create a new one.
     *
     * @param _name   Name of the drip.
     * @param _config Configuration for the drip.
     */
    function create(string calldata _name, DripConfig calldata _config) external onlyOwner {
        // Make sure this drip doesn't already exist. We *must* guarantee that no other function
        // will ever set the status of a drip back to NONE after it's been created. This is why
        // archival is a separate status.
        require(
            drips[_name].status == DripStatus.NONE,
            "Drippie: drip with that name already exists"
        );

        // Validate the drip interval, only allowing an interval of zero if the drip has explicitly
        // been marked as reentrant. Prevents client-side bugs making a drip infinitely executable
        // within the same block (of course, restricted by gas limits).
        if (_config.reentrant) {
            require(
                _config.interval == 0,
                "Drippie: if allowing reentrant drip, must set interval to zero"
            );
        } else {
            require(
                _config.interval > 0,
                "Drippie: interval must be greater than zero if drip is not reentrant"
            );
        }

        // We initialize this way because Solidity won't let us copy arrays into storage yet.
        DripState storage state = drips[_name];
        state.status = DripStatus.PAUSED;
        state.config.reentrant = _config.reentrant;
        state.config.interval = _config.interval;
        state.config.dripcheck = _config.dripcheck;
        state.config.checkparams = _config.checkparams;

        // Solidity doesn't let us copy arrays into storage, so we push each array one by one.
        for (uint256 i = 0; i < _config.actions.length; i++) {
            state.config.actions.push(_config.actions[i]);
        }

        // Tell the world!
        emit DripCreated(_name, _name, _config);
    }

    /**
     * @notice Sets the status for a given drip. The behavior of this function depends on the
     *         status that the user is trying to set. A drip can always move between ACTIVE and
     *         PAUSED, but it can never move back to NONE and once ARCHIVED, it can never move back
     *         to ACTIVE or PAUSED.
     *
     * @param _name   Name of the drip to update.
     * @param _status New drip status.
     */
    function status(string calldata _name, DripStatus _status) external onlyOwner {
        // Make sure we can never set drip status back to NONE. A simple security measure to
        // prevent accidental overwrites if this code is ever updated down the line.
        require(
            _status != DripStatus.NONE,
            "Drippie: drip status can never be set back to NONE after creation"
        );

        // Load the drip status once to avoid unnecessary SLOADs.
        DripStatus curr = drips[_name].status;

        // Make sure the drip in question actually exists. Not strictly necessary but there doesn't
        // seem to be any clear reason why you would want to do this, and it may save some gas in
        // the case of a front-end bug.
        require(
            curr != DripStatus.NONE,
            "Drippie: drip with that name does not exist and cannot be updated"
        );

        // Once a drip has been archived, it cannot be un-archived. This is, after all, the entire
        // point of archiving a drip.
        require(
            curr != DripStatus.ARCHIVED,
            "Drippie: drip with that name has been archived and cannot be updated"
        );

        // Although not strictly necessary, we make sure that the status here is actually changing.
        // This may save the client some gas if there's a front-end bug and the user accidentally
        // tries to "change" the status to the same value as before.
        require(
            curr != _status,
            "Drippie: cannot set drip status to the same status as its current status"
        );

        // If the user is trying to archive this drip, make sure the drip has been paused. We do
        // not allow users to archive active drips so that the effects of this action are more
        // abundantly clear.
        if (_status == DripStatus.ARCHIVED) {
            require(
                curr == DripStatus.PAUSED,
                "Drippie: drip must first be paused before being archived"
            );
        }

        // If we made it here then we can safely update the status.
        drips[_name].status = _status;
        emit DripStatusUpdated(_name, _name, _status);
    }

    /**
     * @notice Checks if a given drip is executable.
     *
     * @param _name Drip to check.
     *
     * @return True if the drip is executable, reverts otherwise.
     */
    function executable(string calldata _name) public view returns (bool) {
        DripState storage state = drips[_name];

        // Only allow active drips to be executed, an obvious security measure.
        require(
            state.status == DripStatus.ACTIVE,
            "Drippie: selected drip does not exist or is not currently active"
        );

        // Don't drip if the drip interval has not yet elapsed since the last time we dripped. This
        // is a safety measure that prevents a malicious recipient from, e.g., spending all of
        // their funds and repeatedly requesting new drips. Limits the potential impact of a
        // compromised recipient to just a single drip interval, after which the drip can be paused
        // by the owner address.
        require(
            state.last + state.config.interval <= block.timestamp,
            "Drippie: drip interval has not elapsed since last drip"
        );

        // Make sure we're allowed to execute this drip.
        require(
            state.config.dripcheck.check(state.config.checkparams),
            "Drippie: dripcheck failed so drip is not yet ready to be triggered"
        );

        // Alright, we're good to execute.
        return true;
    }

    /**
     * @notice Triggers a drip. This function is deliberately left as a public function because the
     *         assumption being made here is that setting the drip to ACTIVE is an affirmative
     *         signal that the drip should be executable according to the drip parameters, drip
     *         check, and drip interval. Note that drip parameters are read entirely from the state
     *         and are not supplied as user input, so there should not be any way for a
     *         non-authorized user to influence the behavior of the drip. Note that the drip check
     *         is executed only **once** at the beginning of the call to the drip function and will
     *         not be executed again between the drip actions within this call.
     *
     * @param _name Name of the drip to trigger.
     */
    function drip(string calldata _name) external {
        DripState storage state = drips[_name];

        // Make sure the drip can be executed. Since executable reverts if the drip is not ready to
        // be executed, we don't need to do an assertion that the returned value is true.
        executable(_name);

        // Update the last execution time for this drip before the call. Note that it's entirely
        // possible for a drip to be executed multiple times per block or even multiple times
        // within the same transaction (via re-entrancy) if the drip interval is set to zero. Users
        // should set a drip interval of 1 if they'd like the drip to be executed only once per
        // block (since this will then prevent re-entrancy).
        state.last = block.timestamp;

        // Update the number of times this drip has been executed. Although this increases the cost
        // of using Drippie, it slightly simplifies the client-side by not having to worry about
        // counting drips via events. Useful for monitoring the rate of drip execution.
        state.count++;

        // Execute each action in the drip. We allow drips to have multiple actions because there
        // are scenarios in which a contract must do multiple things atomically. For example, the
        // contract may need to withdraw ETH from one account and then deposit that ETH into
        // another account within the same transaction.
        uint256 len = state.config.actions.length;
        for (uint256 i = 0; i < len; i++) {
            // Must be marked as "storage" because copying structs into memory is not yet supported
            // by Solidity. Won't significantly reduce gas costs but at least makes it easier to
            // read what the rest of this section is doing.
            DripAction storage action = state.config.actions[i];

            // Actually execute the action. We could use ExcessivelySafeCall here but not strictly
            // necessary (worst case, a drip gets bricked IFF the target is malicious, doubt this
            // will ever happen in practice). Could save a marginal amount of gas to ignore the
            // returndata.
            // slither-disable-next-line calls-loop
            (bool success, ) = action.target.call{ value: action.value }(action.data);

            // Generally should not happen, but could if there's a misconfiguration (e.g., passing
            // the wrong data to the target contract), the recipient is not payable, or
            // insufficient gas was supplied to this transaction. We revert so the drip can be
            // fixed and triggered again later. Means we cannot emit an event to alert of the
            // failure, but can reasonably be detected by off-chain services even without an event.
            // Note that this forces the drip executor to supply sufficient gas to the call
            // (assuming there is some sufficient gas limit that exists, otherwise the drip will
            // not execute).
            require(
                success,
                "Drippie: drip was unsuccessful, please check your configuration for mistakes"
            );
        }

        emit DripExecuted(_name, _name, msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and an event _EventForExposingParamsStructInABI(Params params). This makes it
    // possible to easily encode parameters on the client side. Solidity does not support generics
    // so it's not possible to do this with explicit typing.

    /**
     * @notice Checks whether a drip should be executable.
     *
     * @param _params Encoded parameters for the drip check.
     *
     * @return Whether the drip should be executed.
     */
    function check(bytes memory _params) external view returns (bool);
}
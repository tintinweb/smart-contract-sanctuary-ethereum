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

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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
pragma solidity ^0.8.9;

import { RetroReceiver } from "./RetroReceiver.sol";

/**
 * @title DrippieRedd
 * @notice DrippieRedd goes brrr.
 */
contract DrippieRedd is RetroReceiver {
    /**
     * Enum representing different status options for a given drip.
     */
    enum DripStatus {
        NONE,
        ACTIVE,
        PAUSED
    }

    /**
     * Represents the configuration for a given drip.
     */
    struct DripConfig {
        address payable recipient;
        bytes data;
        bytes checkscript;
        uint256 amount;
        uint256 interval;
    }

    /**
     * Represents the state of an active drip.
     */
    struct DripState {
        DripStatus status;
        DripConfig config;
        uint256 last;
    }

    /**
     * Emitted when a new drip is created.
     */
    event DripCreated(string indexed name, DripConfig config);

    /**
     * Emitted when a drip config is updated.
     */
    event DripConfigUpdated(string indexed name, DripConfig config);

    /**
     * Emitted when a drip status is updated.
     */
    event DripStatusUpdated(string indexed name, DripStatus status);

    /**
     * Emitted when a drip is executed.
     */
    event DripExecuted(string indexed name, address indexed executor, uint256 timestamp);

    /**
     * Maps from drip names to drip states.
     */
    mapping(string => DripState) public drips;

    /**
     * @param _owner Initial owner address.
     */
    constructor(address _owner) RetroReceiver(_owner) {}

    /**
     * Creates a new drip with the given name and configuration.
     *
     * @param _name Name of the drip.
     * @param _config Configuration for the drip.
     */
    function create(string memory _name, DripConfig memory _config) public onlyOwner {
        require(
            drips[_name].status == DripStatus.NONE,
            "DrippieRedd: drip with that name already exists"
        );

        drips[_name] = DripState({ status: DripStatus.ACTIVE, config: _config, last: 0 });

        emit DripCreated(_name, _config);
    }

    /**
     * Configures a drip by name.
     *
     * @param _name Name of the drip to configure.
     * @param _config Drip configuration.
     */
    function update(string memory _name, DripConfig memory _config) public onlyOwner {
        require(
            drips[_name].status != DripStatus.NONE,
            "DrippieRedd: drip with that name does not exist"
        );

        drips[_name].config = _config;

        emit DripConfigUpdated(_name, _config);
    }

    /**
     * Toggles the status of a given drip.
     *
     * @param _name Name of the drip to toggle.
     */
    function toggle(string memory _name) public onlyOwner {
        require(
            drips[_name].status != DripStatus.NONE,
            "DrippieRedd: drip with that name does not exist"
        );

        if (drips[_name].status == DripStatus.ACTIVE) {
            drips[_name].status = DripStatus.PAUSED;
        } else {
            drips[_name].status = DripStatus.ACTIVE;
        }

        emit DripStatusUpdated(_name, drips[_name].status);
    }

    /**
     * Triggers a drip.
     *
     * @param _name Name of the drip to trigger.
     */
    function drip(string memory _name) public {
        DripState storage state = drips[_name];

        require(
            state.status == DripStatus.ACTIVE,
            "DrippieRedd: selected drip does not exist or is not currently active"
        );

        // Don't drip if the drip interval has not yet elapsed since the last time we dripped. This
        // is a safety measure that prevents a malicious recipient from, e.g., spending all of
        // their funds and repeatedly requesting new drips. Limits the potential impact of a
        // compromised recipient to just a single drip interval, after which the drip can be paused
        // by the owner address.
        require(
            state.last + state.config.interval <= block.timestamp,
            "DrippieRedd: drip interval has not elapsed since last drip"
        );

        // Checkscript is a special system for allowing drips to execute arbitrary EVM bytecode to
        // determine whether or not to execute the drip. A checkscript is a simply EVM bytecode
        // snippet that operates with the following requirements:
        // 1. Stack is initialized a single value, address of the drip recipient.
        // 2. Script can do any logic it wants.
        // 3. Script can signal a successful check by leaving a 1 at the top of the stack.
        // 4. Any value other than a 1 on the stack will signal a failed check.
        bytes memory checkscript = state.config.checkscript;
        address payable recipient = state.config.recipient;

        // Balance threshold checks are a common use case for this contract. Using the checkscript
        // system would be unnecessarily expensive for this, so we designate a special bytecode
        // string to be used for balance threshold checks. Specifically, we look for a 33 byte
        // string starting with the 0x00 (STOP) opcode, followed by the uint256 threshold amount.
        // Since a leading STOP opcode would normally halt execution (and be a useless checkscript)
        // we can safely treat this as a special string. Saves ~30k gas.
        bool executable;
        if (checkscript[0] == hex"00" && checkscript.length == 33) {
            assembly {
                let threshold := mload(add(checkscript, 33))
                executable := lt(balance(recipient), threshold)
            }
        } else {
            // Checkscript is only part of the EVM bytecode that actually gets executed on-chain.
            // We prepend a bytecode snippet that pushes the recipient address onto the stack and
            // allows the checkscript to operate on it. We then also append a snippet that takes
            // the final value on the stack and stores it in memory at 0..32 before reverting with
            // that value.
            bytes memory script = abi.encodePacked(
                // Snippet for pushing the recipient address to the stack.
                hex"73",
                recipient,
                // Actual user checkscript.
                checkscript,
                // Checkscript must leave a value on the stack, this cleanup segment will store
                // that value into memory at position 0..32 and then revert with that value which
                // allows us to access that value via returndatacopy below. This is a convenience
                // since checkscripts would otherwise have to do this manually.
                hex"60005260206000FD"
            );

            assembly {
                // Create a contract using the checkscript as initcode. This will execute the EVM
                // instructions included within the checkscript and, hopefully, leave a single 32
                // byte returndata value. We don't actually care about the returned contract
                // address since the script is intended to revert.
                pop(create(0, add(script, 32), mload(script)))

                // We expect the returned data to be exactly 32 bytes. Anything other than 32 bytes
                // will be ignored, which means "executable" will remain false.
                if eq(returndatasize(), 32) {
                    let ret := mload(0x40)
                    mstore(0x40, add(ret, 32))
                    returndatacopy(ret, 0, 32)
                    executable := eq(mload(ret), 1)
                }
            }
        }

        require(
            executable == true,
            "DrippieRedd: checkscript failed so drip is not yet ready to be triggered"
        );

        state.last = block.timestamp;
        (bool success, ) = recipient.call{ value: state.config.amount }(state.config.data);

        // Generally should not happen, but could if there's a misconfiguration (e.g., passing the
        // wrong data to the target contract), the recipient is not payable, or insufficient gas
        // was supplied to this transaction. We revert so the drip can be fixed and triggered again
        // later. Means we cannot emit an event to alert of the failure, but can reasonably be
        // detected by off-chain services even without an event.
        require(
            success == true,
            "DrippieRedd: drip was unsuccessful, check your configuration for mistakes"
        );

        emit DripExecuted(_name, msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Owned } from "@rari-capital/solmate/src/auth/Owned.sol";
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { ERC721 } from "@rari-capital/solmate/src/tokens/ERC721.sol";

/**
 * @title RetroReceiver
 * @notice RetroReceiver is a minimal contract for receiving funds, meant to be deployed at the
 * same address on every chain that supports EIP-2470.
 */
contract RetroReceiver is Owned {
    /**
     * Emitted when ETH is received by this address.
     */
    event ReceivedETH(address indexed from, uint256 amount);

    /**
     * Emitted when ETH is withdrawn from this address.
     */
    event WithdrewETH(address indexed withdrawer, address indexed recipient, uint256 amount);

    /**
     * Emitted when ERC20 tokens are withdrawn from this address.
     */
    event WithdrewERC20(
        address indexed withdrawer,
        address indexed recipient,
        address indexed asset,
        uint256 amount
    );

    /**
     * Emitted when ERC721 tokens are withdrawn from this address.
     */
    event WithdrewERC721(
        address indexed withdrawer,
        address indexed recipient,
        address indexed asset,
        uint256 id
    );

    /**
     * @param _owner Address to initially own the contract.
     */
    constructor(address _owner) Owned(_owner) {}

    /**
     * Make sure we can receive ETH.
     */
    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    /**
     * Withdraws full ETH balance to the recipient.
     *
     * @param _to Address to receive the ETH balance.
     */
    function withdrawETH(address payable _to) public onlyOwner {
        withdrawETH(_to, address(this).balance);
    }

    /**
     * Withdraws partial ETH balance to the recipient.
     *
     * @param _to Address to receive the ETH balance.
     * @param _amount Amount of ETH to withdraw.
     */
    function withdrawETH(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
        emit WithdrewETH(msg.sender, _to, _amount);
    }

    /**
     * Withdraws full ERC20 balance to the recipient.
     *
     * @param _asset ERC20 token to withdraw.
     * @param _to Address to receive the ERC20 balance.
     */
    function withdrawERC20(ERC20 _asset, address _to) public onlyOwner {
        withdrawERC20(_asset, _to, _asset.balanceOf(address(this)));
    }

    /**
     * Withdraws partial ERC20 balance to the recipient.
     *
     * @param _asset ERC20 token to withdraw.
     * @param _to Address to receive the ERC20 balance.
     * @param _amount Amount of ERC20 to withdraw.
     */
    function withdrawERC20(
        ERC20 _asset,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        _asset.transfer(_to, _amount);
        emit WithdrewERC20(msg.sender, _to, address(_asset), _amount);
    }

    /**
     * Withdraws ERC721 token to the recipient.
     *
     * @param _asset ERC721 token to withdraw.
     * @param _to Address to receive the ERC721 token.
     * @param _id Token ID of the ERC721 token to withdraw.
     */
    function withdrawERC721(
        ERC721 _asset,
        address _to,
        uint256 _id
    ) public onlyOwner {
        _asset.transferFrom(address(this), _to, _id);
        emit WithdrewERC721(msg.sender, _to, address(_asset), _id);
    }
}
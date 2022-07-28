// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract VotingToken is ERC20 {
    mapping(address => mapping(address => uint256)) public delegatedVotesPerUser;
    mapping(address => DelegatedVotes) public usersDelegations;
    mapping(address => uint256) public numberOfUserDelegatedVotes;

    address public owner;

    struct DelegatedVotes {
        uint256 amount;
        address delegate;
    }

    constructor() ERC20("VotingToken", "VTN", 18) {
        owner = msg.sender;
    }

    event VotesDelegated(
        address indexed from, address indexed to, uint256 amount
    );
    event VotesUndelegated(
        address indexed from, address indexed to, uint256 amount
    );

    modifier userHasTokens(address addr) {
        require(
            balanceOf[addr] != 0,
            "User should have tokens to preform this operation"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner, "User should be owner to preform this operation"
        );
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == from, "User can only burn own tokens");

        _burn(from, amount);
        _removeDelegatedVotes(from);
    }

    function numberOfVotesAvailable(address addr)
        external
        view
        returns (uint256)
    {
        require(
            usersDelegations[addr].amount <= balanceOf[addr],
            "User has delegated all his tokens"
        );
        return balanceOf[addr]
            - usersDelegations[addr].amount
            + numberOfUserDelegatedVotes[addr];
    }

    function delegateVotes(address to, uint256 amount)
        external
        userHasTokens(msg.sender)
        userHasTokens(to)
        returns (bool)
    {
        require(msg.sender != to, "Delegation votes to yourself is prohibited");
        require(
            delegatedVotesPerUser[to][msg.sender] + amount <= balanceOf[msg.sender],
            "User doesn't have enough tokens to delegate"
        );

        // user doesn't have any votes delegated
        if (getUserDelegate(msg.sender) == address(0)) {
            numberOfUserDelegatedVotes[to] += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;
            usersDelegations[msg.sender] = DelegatedVotes(amount, to);
            return true;
        }

        // user wants to delegate more votes to same address
        if (usersDelegations[msg.sender].delegate == to) {
            numberOfUserDelegatedVotes[to] += amount;
            usersDelegations[msg.sender].amount += amount;
            delegatedVotesPerUser[to][msg.sender] += amount;

            return true;
        }

        // user wants to delegate votes to another address
        _removeDelegatedVotes(msg.sender);
        numberOfUserDelegatedVotes[to] += amount;
        delegatedVotesPerUser[to][msg.sender] += amount;
        usersDelegations[msg.sender].amount += amount;
        usersDelegations[msg.sender].delegate = to;

        emit VotesDelegated(msg.sender, to, amount);

        return true;
    }

    function removeDelegatedVotes() external userHasTokens(msg.sender) {
        address delegate = getUserDelegate(msg.sender);
        require(delegate != address(0), "User hasn't yet delegated any votes");

        uint256 amountOfDelegatedVotes = usersDelegations[msg.sender].amount;

        numberOfUserDelegatedVotes[delegate] -= amountOfDelegatedVotes;
        usersDelegations[msg.sender].amount -= amountOfDelegatedVotes;
        usersDelegations[msg.sender].delegate = address(0);
        delegatedVotesPerUser[delegate][msg.sender] -= amountOfDelegatedVotes;

        emit VotesUndelegated(msg.sender, delegate, amountOfDelegatedVotes);
    }

    function _removeDelegatedVotes(address initiator)
        private
        userHasTokens(initiator)
    {
        address delegate = getUserDelegate(initiator);
        require(delegate != address(0), "User hasn't yet delegated any votes");

        uint256 amountOfDelegatedVotes = usersDelegations[initiator].amount;

        numberOfUserDelegatedVotes[delegate] -= amountOfDelegatedVotes;
        usersDelegations[initiator].amount -= amountOfDelegatedVotes;
        usersDelegations[initiator].delegate = address(0);
        delegatedVotesPerUser[delegate][initiator] -= amountOfDelegatedVotes;

        emit VotesUndelegated(initiator, delegate, amountOfDelegatedVotes);
    }

    function getUserDelegate(address addr) private view returns (address) {
        address delegate = usersDelegations[addr].delegate;

        if (delegate != address(0)) {
            return delegate;
        }

        return address(0);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _removeDelegatedVotes(msg.sender);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] =
            allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _removeDelegatedVotes(from);

        emit Transfer(from, to, amount);

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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
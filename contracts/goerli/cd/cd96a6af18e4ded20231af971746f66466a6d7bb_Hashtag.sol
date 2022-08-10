// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 *  @title Simple Deal Hashtag
 *  @dev Created in Swarm City anno 2017,
 *  for the world, with love.
 *  description Symmetrical Escrow Deal Contract
 *  description This is the hashtag contract for creating Swarm City marketplaces.
 *  It's the first, most simple approach to making Swarm City work.
 *  This contract creates "SimpleDeals".
 */

import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Auth, Authority } from 'solmate/auth/Auth.sol';
import { SafeTransferLib } from 'solmate/utils/SafeTransferLib.sol';

import { MintableERC20 } from './MintableERC20.sol';

// @notice Status enum
enum Status {
	None,
	Open,
	Funded,
	Done,
	Disputed,
	Resolved,
	Cancelled
}

contract Hashtag is Auth {
	/// @dev name The human readable name of the hashtag
	/// @dev fee The fixed hashtag fee in the specified token
	/// @dev token The token for fees
	/// @dev providerRep The rep token that is minted for the Provider
	/// @dev seekerRep The rep token that is minted for the Seeker
	/// @dev payoutaddress The address where the hashtag fee is sent.
	/// @dev metadataHash The IPFS hash metadata for this hashtag
	string public name;
	uint256 public fee;
	ERC20 public token;
	MintableERC20 public providerRep;
	MintableERC20 public seekerRep;
	address public payoutAddress;
	string public metadataHash;

	/// @param dealStruct The deal object.
	/// @param status Coming from Status enum.
	/// Statuses: Open, Done, Disputed, Resolved, Cancelled
	/// @param fee The value of the hashtag fee is stored in the deal. This prevents the hashtagmaintainer to influence an existing deal when changing the hashtag fee.
	/// @param dealValue The value of the deal (SWT)
	/// @param provider The address of the provider
	/// @param deals Array of deals made by this hashtag

	struct Item {
		Status status;
		uint256 fee;
		uint256 price;
		uint256 providerRep;
		uint256 seekerRep;
		address providerAddress;
		address seekerAddress;
		string metadata;
	}

	mapping(bytes32 => Item) public items;

	/// @dev Event NewDealForTwo - This event is fired when a new deal for two is created.
	event NewItem(
		address indexed owner,
		bytes32 indexed id,
		string metadata,
		uint256 price,
		uint256 fee,
		uint256 seekerRep
	);

	/// @dev Event FundDeal - This event is fired when a deal is been funded by a party.
	event FundItem(address indexed provider, bytes32 indexed id);

	/// @dev DealStatusChange - This event is fired when a deal status is updated.
	event ItemStatusChange(bytes32 indexed id, Status newstatus);

	/// @dev hashtagChanged - This event is fired when the payout address is changed.
	event SetPayoutAddress(address payoutAddress);

	/// @dev hashtagChanged - This event is fired when the metadata hash is changed.
	event SetMetadataHash(string metadataHash);

	/// @dev hashtagChanged - This event is fired when the hashtag fee is changed.
	event SetFee(uint256 fee);

	/// @notice The function that creates the hashtag
	constructor() Auth(address(0), Authority(address(0))) {}

	/// @notice The function that initializes the hashtag
	function init(
		address _token,
		string memory _name,
		uint256 _fee,
		string memory _metadataHash,
		address _owner,
		MintableERC20 _seekerRep,
		MintableERC20 _providerRep
	) public {
		require(token == ERC20(address(0)), 'ALREADY_INITIALIZED');
		require(_token != address(0), 'INVALID_TOKEN');

		// Reputation tokens
		seekerRep = _seekerRep;
		providerRep = _providerRep;

		// Global config
		name = _name;
		token = ERC20(_token);
		metadataHash = _metadataHash;
		fee = _fee;
		payoutAddress = msg.sender;

		// Auth
		owner = _owner;
	}

	/// @notice The Hashtag owner can always update the payout address.
	function setPayoutAddress(address _payoutaddress) public requiresAuth {
		payoutAddress = _payoutaddress;
		emit SetPayoutAddress(payoutAddress);
	}

	/// @notice The Hashtag owner can always update the metadata for the hashtag.
	function setMetadataHash(string calldata _metadataHash) public requiresAuth {
		metadataHash = _metadataHash;
		emit SetMetadataHash(metadataHash);
	}

	/// @notice The Hashtag owner can always change the hashtag fee amount
	function setFee(uint256 _fee) public requiresAuth {
		fee = _fee;
		emit SetFee(fee);
	}

	/// @notice The item making stuff

	/// @notice The create item function
	function newItem(
		bytes32 _id,
		uint256 _price,
		string calldata _metadata
	) public {
		// fund this deal
		uint256 totalValue = _price + fee / 2;

		// if deal already exists don't allow to overwrite it
		require(items[_id].status == Status.None, 'ITEM_ALREADY_EXISTS');

		// @dev The Seeker transfers SWT to the hashtagcontract
		SafeTransferLib.safeTransferFrom(
			token,
			msg.sender,
			address(this),
			totalValue
		);

		// @dev The Seeker pays half of the fee to the Maintainer
		SafeTransferLib.safeTransfer(token, payoutAddress, fee / 2);

		// Seeker rep (cache to save an external call)
		uint256 rep = seekerRep.balanceOf(msg.sender);

		// if it's funded - fill in the details
		items[_id] = Item(
			Status.Open,
			fee,
			_price,
			0,
			rep,
			address(0),
			msg.sender,
			_metadata
		);

		emit NewItem(msg.sender, _id, _metadata, _price, fee, rep);
	}

	/// @notice Provider has to fund the deal
	function fundItem(bytes memory preImage) public {
		bytes32 id = keccak256(preImage);
		Item storage item = items[id];

		/// @dev only allow open deals to be funded
		require(item.status == Status.Open, 'ITEM_NOT_OPEN');

		/// @dev put the tokens from the provider on the deal
		SafeTransferLib.safeTransferFrom(
			token,
			msg.sender,
			address(this),
			item.price + item.fee / 2
		);

		// @dev The Seeker pays half of the fee to the Maintainer
		SafeTransferLib.safeTransfer(token, payoutAddress, item.fee / 2);

		/// @dev fill in the address of the provider (to payout the deal later on)
		item.providerAddress = msg.sender;
		item.providerRep = providerRep.balanceOf(msg.sender);
		item.status = Status.Funded;

		emit FundItem(item.providerAddress, id);
	}

	/// @notice The payout function can only be called by the deal owner.
	function payoutItem(bytes32 _id) public {
		Item storage item = items[_id];

		/// @dev Only Seeker can payout
		require(item.seekerAddress == msg.sender, 'UNAUTHORIZED');

		/// @dev you can only payout open deals
		require(item.status == Status.Funded, 'DEAL_NOT_FUNDED');

		/// @dev pay out the provider
		SafeTransferLib.safeTransfer(token, item.providerAddress, item.price * 2);

		/// @dev mint REP for Provider
		providerRep.mint(item.providerAddress, 5);

		/// @dev mint REP for Seeker
		seekerRep.mint(item.seekerAddress, 5);

		/// @dev mark the deal as done
		item.status = Status.Done;
		emit ItemStatusChange(_id, Status.Done);
	}

	/// @notice The Cancel Item Function
	/// @notice Half of the fee is sent to PayoutAddress
	function cancelItem(bytes32 _id) public {
		Item storage item = items[_id];
		require(item.status == Status.Open, 'DEAL_NOT_OPEN');
		require(item.seekerAddress == msg.sender, 'UNAUTHORIZED');

		SafeTransferLib.safeTransfer(token, item.seekerAddress, item.price);

		item.status = Status.Cancelled;
		emit ItemStatusChange(_id, Status.Cancelled);
	}

	/// @notice The Dispute Item Function
	/// @notice The Seeker or Provider can dispute an item, only the Maintainer can resolve it.
	function disputeItem(bytes32 _id) public {
		Item storage item = items[_id];
		require(item.status == Status.Funded, 'DEAL_NOT_FUNDED');
		require(
			item.providerAddress == msg.sender || item.seekerAddress == msg.sender,
			'UNAUTHORIZED'
		);

		/// @dev Set itemStatus to Disputed
		item.status = Status.Disputed;
		emit ItemStatusChange(_id, Status.Disputed);
	}

	/// @notice The Resolve Item Function ♡
	/// @notice The Maintainer resolves the disputed item.
	function resolveItem(bytes32 _id, uint256 _seekerFraction) public {
		Item storage item = items[_id];
		require(msg.sender == payoutAddress, 'UNAUTHORIZED');
		require(item.status == Status.Disputed, 'DEAL_NOT_DISPUTED');

		SafeTransferLib.safeTransfer(token, item.seekerAddress, _seekerFraction);
		SafeTransferLib.safeTransfer(
			token,
			item.providerAddress,
			item.price * 2 - _seekerFraction
		);

		item.status = Status.Resolved;
		emit ItemStatusChange(_id, Status.Resolved);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Auth, Authority } from 'solmate/auth/Auth.sol';

contract MintableERC20 is ERC20, Auth {
	constructor(uint8 _decimals)
		ERC20('', '', _decimals)
		Auth(address(0), Authority(address(0)))
	{}

	function init(
		string memory _name,
		string memory _symbol,
		address _owner
	) public {
		require(owner == address(0), 'ALREADY_INITIALIZED');

		name = _name;
		symbol = _symbol;
		owner = _owner;
	}

	function mint(address to, uint256 amount) external requiresAuth {
		_mint(to, amount);
	}
}
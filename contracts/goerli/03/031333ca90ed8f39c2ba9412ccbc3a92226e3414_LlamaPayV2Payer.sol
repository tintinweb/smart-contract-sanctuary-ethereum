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

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

interface IERC20Permit{
     /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "./BoringBatchable.sol";

interface Factory {
    function param() external view returns (address);
}

error NOT_OWNER();
error NOT_OWNER_OR_WHITELISTED();
error INVALID_ADDRESS();
error INVALID_TIME();
error INVALID_STREAM();
error PAYER_IN_DEBT();
error INACTIVE_STREAM();
error ACTIVE_STREAM();
error STREAM_ACTIVE_OR_REDEEMABLE();

/// @title LlamaPayV2 Payer Contract
/// @author nemusona
contract LlamaPayV2Payer is ERC721, BoringBatchable {
    using SafeTransferLib for ERC20;

    struct Token {
        uint256 balance;
        uint256 totalPaidPerSec;
        uint208 divisor;
        uint48 lastUpdate;
    }

    struct Stream {
        uint208 amountPerSec;
        uint48 lastPaid;
        address token;
        uint48 starts;
        uint48 ends;
        uint256 redeemable;
    }

    address public owner;
    uint256 public nextTokenId;

    mapping(address => Token) public tokens;
    mapping(uint256 => Stream) public streams;
    mapping(address => uint256) public payerWhitelists;
    mapping(uint256 => address) public redirects;
    mapping(uint256 => mapping(address => uint256)) public streamWhitelists;
    mapping(uint256 => uint256) public debts;

    event Deposit(address token, address from, uint256 amount);
    event WithdrawPayer(address token, address to, uint256 amount);
    event Withdraw(uint256 id, address token, address to, uint256 amount);
    event CreateStream(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    );
    event CreateStreamWithReason(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        string reason
    );
    event CreateStreamWithheld(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        uint256 withheldPerSec
    );
    event CreateStreamWithheldWithReason(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends,
        uint256 withheldPerSec,
        string reason
    );
    event AddPayerWhitelist(address whitelisted);
    event RemovePayerWhitelist(address removed);
    event AddRedirectStream(uint256 id, address redirected);
    event RemoveRedirectStream(uint256 id);
    event AddStreamWhitelist(uint256 id, address whitelisted);
    event RemoveStreamWhitelist(uint256 id, address removed);

    constructor() ERC721("LlamaPay V2 Stream", "LLAMAPAY-V2-STREAM") {
        owner = Factory(msg.sender).param();
    }

    modifier onlyOwnerAndWhitelisted() {
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_OWNER();
        _;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return "";
    }

    /// @notice deposit into vault (anybody can deposit)
    /// @param _token token
    /// @param _amount amount (native token decimal)
    function deposit(address _token, uint256 _amount) external {
        ERC20 token = ERC20(_token);
        // Stores token divisor if it is the first time being deposited
        // Saves on having to call decimals() for conversions
        if (tokens[_token].divisor == 0) {
            unchecked {
                tokens[_token].divisor = uint208(10**(20 - token.decimals()));
            }
        }
        tokens[_token].balance += _amount * tokens[_token].divisor;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    /// @notice withdraw tokens that have not been streamed yet
    /// @param _token token
    /// @param _amount amount (native token decimals)
    function withdrawPayer(address _token, uint256 _amount)
        external
        onlyOwnerAndWhitelisted
    {
        _updateToken(_token);
        uint256 toDeduct;
        unchecked {
            toDeduct = _amount * tokens[_token].divisor;
        }
        /// Will revert if not enough after updating Token struct
        tokens[_token].balance -= toDeduct;
        ERC20(_token).safeTransfer(msg.sender, _amount);
        emit WithdrawPayer(_token, msg.sender, _amount);
    }

    /// @notice withdraw from stream
    /// @param _id token id
    /// @param _amount amount (native decimals)
    function withdraw(uint256 _id, uint256 _amount) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        address nftOwner = ownerOf(_id);
        if (
            msg.sender != nftOwner &&
            msg.sender != owner &&
            streamWhitelists[_id][msg.sender] != 1
        ) revert NOT_OWNER_OR_WHITELISTED();
        _updateStream(_id);
        Stream storage stream = streams[_id];

        /// Reverts if payee is going to rug
        streams[_id].redeemable -= _amount * tokens[stream.token].divisor;

        address to;
        address redirect = redirects[_id];
        if (redirect != address(0)) {
            to = redirect;
        } else {
            to = nftOwner;
        }

        ERC20(stream.token).safeTransfer(to, _amount);
        emit Withdraw(_id, stream.token, to, _amount);
    }

    /// @notice creates stream
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    function createStream(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec, _starts, _ends);
        emit CreateStream(id, _token, _to, _amountPerSec, _starts, _ends);
    }

    /// @notice creates stream with a reason string
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    /// @param _reason reason
    function createStreamWithReason(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends,
        string memory _reason
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec, _starts, _ends);
        emit CreateStreamWithReason(
            id,
            _token,
            _to,
            _amountPerSec,
            _starts,
            _ends,
            _reason
        );
    }

    /// @notice creates stream with amount withheld
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    /// @param _withheldPerSec withheld per sec (20 decimals)
    function createStreamWithheld(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends,
        uint256 _withheldPerSec
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec, _starts, _ends);
        emit CreateStreamWithheld(
            id,
            _token,
            _to,
            _amountPerSec,
            _starts,
            _ends,
            _withheldPerSec
        );
    }

    /// @notice creates stream with a reason string and withheld
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    /// @param _withheldPerSec withheld per sec (20 decimals)
    /// @param _reason reason
    function createStreamWithheldWithReason(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends,
        uint256 _withheldPerSec,
        string memory _reason
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec, _starts, _ends);
        emit CreateStreamWithheldWithReason(
            id,
            _token,
            _to,
            _amountPerSec,
            _starts,
            _ends,
            _withheldPerSec,
            _reason
        );
    }

    /// @notice modifies current stream (RESTARTS STREAM)
    /// @param _id token id
    /// @param _newAmountPerSec modified amount per sec (20 decimals)
    /// @param _newEnd new end time
    function modifyStream(
        uint256 _id,
        uint208 _newAmountPerSec,
        uint48 _newEnd
    ) external onlyOwnerAndWhitelisted {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        _updateStream(_id);
        Stream storage stream = streams[_id];
        /// Prevents people from setting end to time already "paid out"
        if (block.timestamp >= _newEnd) revert INVALID_TIME();

        tokens[stream.token].totalPaidPerSec += _newAmountPerSec;
        unchecked {
            /// Prevents incorrect totalPaidPerSec calculation if stream is inactive
            if (stream.lastPaid > 0) {
                tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
                uint256 lastUpdate = tokens[stream.token].lastUpdate;
                /// Track debt if payer is in debt
                if (block.timestamp > lastUpdate) {
                    /// Add debt owed til modify call
                    debts[_id] +=
                        (block.timestamp - lastUpdate) *
                        stream.amountPerSec;
                }
            }
            streams[_id].amountPerSec = _newAmountPerSec;
            streams[_id].ends = _newEnd;
            streams[_id].lastPaid = uint48(block.timestamp);
        }
    }

    /// @notice Stops current stream
    /// @param _id token id
    function stopStream(uint256 _id, bool _payDebt)
        external
        onlyOwnerAndWhitelisted
    {
        if (_id >= nextTokenId) revert INVALID_STREAM();

        _updateStream(_id);
        Stream storage stream = streams[_id];
        if (stream.lastPaid == 0) revert INACTIVE_STREAM();

        unchecked {
            uint256 lastUpdate = tokens[stream.token].lastUpdate;
            /// If chooses to pay debt and payer is in debt
            if (_payDebt && block.timestamp > lastUpdate) {
                /// Track owed until stopStream call
                debts[_id] +=
                    (block.timestamp - lastUpdate) *
                    stream.amountPerSec;
            }
            streams[_id].lastPaid = 0;
            tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
        }
    }

    /// @notice resumes a stopped stream
    /// @param _id token id
    function resumeStream(uint256 _id) external onlyOwnerAndWhitelisted {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        Stream storage stream = streams[_id];
        if (stream.lastPaid > 0) revert ACTIVE_STREAM();
        /// Cannot resume an already ended stream
        if (block.timestamp >= stream.ends) revert INVALID_TIME();

        _updateToken(stream.token);
        if (block.timestamp > tokens[stream.token].lastUpdate)
            revert PAYER_IN_DEBT();

        tokens[stream.token].totalPaidPerSec += stream.amountPerSec;
        unchecked {
            streams[_id].lastPaid = uint48(block.timestamp);
        }
    }

    /// @notice burns an inactive and withdrawn stream
    /// @param _id token id
    function burnStream(uint256 _id) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (
            msg.sender != owner &&
            payerWhitelists[msg.sender] != 1 &&
            msg.sender != ownerOf(_id)
        ) revert NOT_OWNER_OR_WHITELISTED();
        Stream storage stream = streams[_id];
        /// Prevents somebody from burning an active stream or a stream with balance in it
        if (stream.redeemable > 0 || stream.lastPaid > 0)
            revert STREAM_ACTIVE_OR_REDEEMABLE();

        _burn(_id);
    }

    /// @notice manually update stream
    /// @param _id token id
    function updateStream(uint256 _id) external onlyOwnerAndWhitelisted {
        _updateStream(_id);
    }

    /// @notice repay debt
    /// @param _id token id
    function repayDebt(uint256 _id) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (
            msg.sender != owner &&
            payerWhitelists[msg.sender] != 1 &&
            msg.sender != ownerOf(_id)
        ) revert NOT_OWNER_OR_WHITELISTED();

        _updateStream(_id);
        unchecked {
            uint256 debt = debts[_id];
            address token = streams[_id].token;
            uint256 balance = tokens[token].balance;
            if (debt > 0) {
                /// If payer balance has enough to pay back debt
                if (balance >= debt) {
                    /// Deduct debt from payer balance and debt is repaid
                    tokens[token].balance -= debt;
                    streams[_id].redeemable += debt;
                    debts[_id] = 0;
                } else {
                    /// Get remaining debt after payer balance is depleted
                    debts[_id] = debt - balance;
                    streams[_id].redeemable += balance;
                    tokens[token].balance = 0;
                }
            }
        }
    }

    /// @notice add address to payer whitelist
    /// @param _toAdd address to whitelist
    function addPayerWhitelist(address _toAdd) external onlyOwner {
        payerWhitelists[_toAdd] = 1;
        emit AddPayerWhitelist(_toAdd);
    }

    /// @notice remove address to payer whitelist
    /// @param _toRemove address to remove from whitelist
    function removePayerWhitelist(address _toRemove) external onlyOwner {
        payerWhitelists[_toRemove] = 0;
        emit RemovePayerWhitelist(_toRemove);
    }

    /// @notice add redirect to stream
    /// @param _id token id
    /// @param _redirectTo address to redirect funds to
    function addRedirectStream(uint256 _id, address _redirectTo) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        redirects[_id] = _redirectTo;
        emit AddRedirectStream(_id, _redirectTo);
    }

    /// @notice remove redirect to stream
    /// @param _id token id
    function removeRedirectStream(uint256 _id) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        redirects[_id] = address(0);
        emit RemoveRedirectStream(_id);
    }

    /// @notice add whitelist to stream
    /// @param _id token id
    /// @param _toAdd address to whitelist
    function addStreamWhitelist(uint256 _id, address _toAdd) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        streamWhitelists[_id][_toAdd] = 1;
        emit AddStreamWhitelist(_id, _toAdd);
    }

    /// @notice remove whitelist to stream
    /// @param _id token id
    /// @param _toRemove address to remove from whitelist
    function removeStreamWhitelist(uint256 _id, address _toRemove) external {
        if (_id >= nextTokenId) revert INVALID_STREAM();
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        streamWhitelists[_id][_toRemove] = 0;
        emit RemoveStreamWhitelist(_id, _toRemove);
    }

    /// @notice create stream
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    function _createStream(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends
    ) private onlyOwnerAndWhitelisted returns (uint256 id) {
        if (_to == address(0)) revert INVALID_ADDRESS();
        if (_starts >= _ends) revert INVALID_TIME();
        _updateToken(_token);
        if (block.timestamp > tokens[_token].lastUpdate) revert PAYER_IN_DEBT();

        uint256 owed;
        if (block.timestamp > _starts) {
            /// Calculates amount streamed from start to stream creation
            owed = (block.timestamp - _starts) * _amountPerSec;
            /// Will revert if cannot pay owed balance
            tokens[_token].balance -= owed;
        }

        tokens[_token].totalPaidPerSec += _amountPerSec;
        id = nextTokenId;
        _safeMint(_to, id);
        streams[id] = Stream({
            amountPerSec: _amountPerSec,
            token: _token,
            lastPaid: uint48(block.timestamp),
            starts: _starts,
            ends: _ends,
            redeemable: owed
        });
        unchecked {
            nextTokenId++;
        }
    }

    /// @notice updates token balances
    /// @param _token token to update
    function _updateToken(address _token) private {
        Token storage token = tokens[_token];
        /// Streamed from last update to called
        uint256 streamed = (block.timestamp - token.lastUpdate) *
            token.totalPaidPerSec;
        unchecked {
            if (token.balance >= streamed) {
                /// If enough to pay owed then deduct from balance and update to current timestamp
                tokens[_token].balance -= streamed;
                tokens[_token].lastUpdate = uint48(block.timestamp);
            } else {
                /// If not enough then get remainder paying as much as possible then calculating and adding time paid
                tokens[_token].lastUpdate += uint48(
                    token.balance / token.totalPaidPerSec
                );
                tokens[_token].balance = token.balance % token.totalPaidPerSec;
            }
        }
    }

    /// @notice update stream
    /// @param _id token id
    function _updateStream(uint256 _id) private {
        /// Update Token info to get last update
        Stream storage stream = streams[_id];
        _updateToken(stream.token);
        uint48 lastUpdate = tokens[stream.token].lastUpdate;

        /// If stream is inactive/cancelled
        if (stream.lastPaid == 0) {
            /// Can only withdraw redeeemable so do nothing
        }
        /// Stream not updated after start and has ended
        else if (
            /// Stream not updated after start
            stream.starts > stream.lastPaid &&
            /// Stream ended
            lastUpdate >= stream.ends
        ) {
            /// Refund payer for:
            /// Stream last updated to stream start
            /// Stream ended to token last updated
            tokens[stream.token].balance +=
                ((stream.starts - stream.lastPaid) +
                    (lastUpdate - stream.ends)) *
                stream.amountPerSec;
            /// Payee can redeem:
            /// Stream start to end
            streams[_id].redeemable =
                (stream.ends - stream.starts) *
                stream.amountPerSec;
            unchecked {
                /// Stream is now inactive
                streams[_id].lastPaid = 0;
                tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
            }
        }
        /// Stream started but has not been updated from before start
        else if (
            /// Stream started
            lastUpdate >= stream.starts &&
            /// Strean not updated after start
            stream.starts > stream.lastPaid
        ) {
            /// Refund payer for:
            /// Stream last updated to stream start
            tokens[stream.token].balance +=
                (stream.starts - stream.lastPaid) *
                stream.amountPerSec;
            /// Payer can redeem:
            /// Stream start to last token update
            streams[_id].redeemable =
                (lastUpdate - stream.starts) *
                stream.amountPerSec;
            unchecked {
                streams[_id].lastPaid = lastUpdate;
            }
        }
        /// Stream has ended
        else if (
            /// Stream ended
            lastUpdate >= stream.ends
        ) {
            /// Refund payer for:
            /// Stream end to last token update
            tokens[stream.token].balance +=
                (lastUpdate - stream.ends) *
                stream.amountPerSec;
            /// Add redeemable for:
            /// Stream last updated to stream end
            streams[_id].redeemable +=
                (stream.ends - stream.lastPaid) *
                stream.amountPerSec;
            /// Stream is now inactive
            unchecked {
                streams[_id].lastPaid = 0;
                tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
            }
        }
        /// Stream is updated before stream starts
        else if (
            /// Stream not started
            stream.starts > lastUpdate
        ) {
            /// Refund payer:
            /// Last stream update to last token update
            tokens[stream.token].balance +=
                (lastUpdate - stream.lastPaid) *
                stream.amountPerSec;
            unchecked {
                /// update lastpaid to last token update
                streams[_id].lastPaid = lastUpdate;
            }
        }
        /// Updated after start, and has not ended
        else if (
            /// Stream started
            stream.lastPaid >= stream.starts &&
            /// Stream has not ended
            stream.ends > lastUpdate
        ) {
            /// Add redeemable for:
            /// stream last update to last token update
            streams[_id].redeemable +=
                (lastUpdate - stream.lastPaid) *
                stream.amountPerSec;
            unchecked {
                streams[_id].lastPaid = lastUpdate;
            }
        }
    }
}
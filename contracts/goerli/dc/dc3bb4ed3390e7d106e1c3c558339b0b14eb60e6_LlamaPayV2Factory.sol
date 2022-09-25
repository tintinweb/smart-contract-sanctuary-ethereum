//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./LlamaPayV2Payer.sol";
import "./BoringBatchable.sol";

error AlreadyDeployed();

contract LlamaPayV2Factory is BoringBatchable {
    bytes32 constant INIT_CODEHASH =
        keccak256(type(LlamaPayV2Payer).creationCode);

    uint256 public ownerCount;
    address public param;

    mapping(uint256 => address) public ownerContracts;
    mapping(address => mapping(address => uint256)) public withdrawalWhitelists;
    mapping(address => address) public redirects;

    event LlamaPayContractCreated(address owner, address ownerContract);

    /// @notice Creates LlamaPay V2 Payer contract
    function createLlamaPayContract() external returns (address llamapay) {
        param = msg.sender;
        llamapay = address(
            new LlamaPayV2Payer{salt: bytes32(uint256(uint160(msg.sender)))}()
        );
        ownerContracts[ownerCount] = llamapay;
        unchecked {
            ownerCount++;
        }
        emit LlamaPayContractCreated(msg.sender, llamapay);
    }

    /// @notice set redirect for sender
    /// @param _redirectTo address to redirect to
    function setRedirect(address _redirectTo) external {
        redirects[msg.sender] = _redirectTo;
    }

    /// @notice reset redirect for sender
    function resetRedirect() external {
        redirects[msg.sender] = address(0);
    }

    /// @notice approve whitelisting for withdrawals
    /// @param _toApprove address to approve
    function approveWithdrawalWhitelist(address _toApprove) external {
        withdrawalWhitelists[msg.sender][_toApprove] = 1;
    }

    /// @notice revoke whitelisting for withdrawals
    function revokeWithdrawalWhitelist(address _toRevoke) external {
        withdrawalWhitelists[msg.sender][_toRevoke] = 0;
    }

    /// @notice Calculates CREATE2 address for payer
    /// @param _owner owner
    function calculateLlamaPayAddress(address _owner)
        public
        view
        returns (address predicted, bool deployed)
    {
        predicted = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(uint256(uint160(_owner))),
                            INIT_CODEHASH
                        )
                    )
                )
            )
        );
        deployed = predicted.code.length != 0;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "./LlamaPayV2Factory.sol";
import "./BoringBatchable.sol";

error NOT_OWNER();
error NOT_OWNER_OR_WHITELISTED();
error RECIPIENT_IS_ZERO();
error OWNER_IS_ZERO();
error STREAM_PAUSED_OR_CANCELLED();
error STREAM_ACTIVE();
error AMOUNT_NOT_AVAILABLE();
error PAYER_IN_DEBT();
error NOT_WHITELISTED();

/// @title LlamaPayV2 Payer Contract
/// @author nemusona
contract LlamaPayV2Payer is ERC721, BoringBatchable {
    using SafeTransferLib for ERC20;

    struct Token {
        uint256 balance;
        uint256 totalPaidPerSec;
        uint216 divisor;
        uint40 lastUpdate;
    }

    struct Stream {
        uint256 amountPerSec;
        address token;
        uint96 paidUpTo;
    }

    address public immutable factory;
    address public immutable owner;
    uint256 public tokenId;

    mapping(address => Token) public tokens;
    mapping(uint256 => Stream) public streams;
    mapping(address => uint256) public payerWhitelists;

    event Deposit(address token, address from, uint256 amount);
    event WithdrawPayer(address token, address to, uint256 amount);
    event Withdraw(uint256 id, address token, address to, uint256 amount);
    event CreateStream(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec
    );
    event CreateStreamWithheld(
        uint256 id,
        address token,
        address to,
        uint256 amountPerSec,
        uint256 withhheldPerSec
    );
    event CancelStream(uint256 id);
    event ModifyStream(uint256 id, uint256 newAmountPerSec);
    event ResumeStream(uint256 id);
    event PauseStream(uint256 id);

    constructor() ERC721("LlamaPayV2 Stream", "LLAMAPAYV2-STREAM") {
        factory = msg.sender;
        owner = LlamaPayV2Factory(msg.sender).param();
    }

    /// @notice update token balance
    /// @param _token token to be updated
    function _update(address _token) private {
        Token storage token = tokens[_token];
        uint256 delta = block.timestamp - token.lastUpdate;

        unchecked {
            uint256 streamed = delta * token.totalPaidPerSec;
            if (token.balance >= streamed) {
                tokens[_token].balance -= streamed;
                tokens[_token].lastUpdate = uint40(block.timestamp);
            } else {
                tokens[_token].balance = token.balance % token.totalPaidPerSec;
                tokens[_token].lastUpdate += uint40(
                    token.balance / token.totalPaidPerSec
                );
            }
        }
    }

    /// @notice deposit into vault
    /// @param _token token to deposit
    /// @param _amount amount to deposit (native decimal)
    function deposit(address _token, uint256 _amount) external {
        ERC20 token = ERC20(_token);
        if (tokens[_token].divisor == 0) {
            tokens[_token].divisor = uint216(10**(20 - token.decimals()));
        }
        tokens[_token].balance += _amount * tokens[_token].divisor;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    /// @notice withdraw unstreamed tokens
    /// @param _token token to withdraw
    /// @param _amount amount to withdraw (20 decimals)
    function withdrawPayer(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();

        _update(_token);
        tokens[_token].balance -= _amount;

        ERC20 token = ERC20(_token);
        uint256 toWithdraw;
        unchecked {
            toWithdraw = _amount / tokens[_token].divisor;
        }
        token.safeTransfer(_to, toWithdraw);
        emit WithdrawPayer(_token, _to, _amount);
    }

    /// @notice withdraw from stream
    /// @param _id token id
    /// @param _amount amount to withdraw (20 decimals)
    function withdraw(uint256 _id, uint256 _amount) external {
        (ERC20 token, address transferTo, uint256 toWithdraw) = _withdraw(
            _id,
            _amount
        );
        token.safeTransfer(transferTo, toWithdraw);
    }

    /// @notice withdraw from stream
    /// @param _id token id
    /// @param _amount amount to withdraw (20 decimals)
    function _withdraw(uint256 _id, uint256 _amount)
        private
        returns (
            ERC20 token,
            address transferTo,
            uint256 toWithdraw
        )
    {
        Stream storage stream = streams[_id];
        address nftOwner = ownerOf(_id);
        if (
            msg.sender != nftOwner &&
            LlamaPayV2Factory(factory).withdrawalWhitelists(
                nftOwner,
                msg.sender
            ) !=
            1 &&
            msg.sender != owner
        ) revert NOT_OWNER_OR_WHITELISTED();

        if (stream.paidUpTo == 0) revert STREAM_PAUSED_OR_CANCELLED();

        _update(stream.token);

        uint256 delta = tokens[stream.token].lastUpdate - stream.paidUpTo;
        uint256 available = delta * stream.amountPerSec;
        if (_amount > available) revert AMOUNT_NOT_AVAILABLE();

        unchecked {
            streams[_id].paidUpTo += uint96(_amount / stream.amountPerSec);
        }

        token = ERC20(stream.token);

        unchecked {
            toWithdraw = _amount / tokens[stream.token].divisor;
        }

        address redirect = LlamaPayV2Factory(factory).redirects(nftOwner);
        if (redirect != address(0)) {
            transferTo = redirect;
        } else {
            transferTo = nftOwner;
        }
        emit Withdraw(_id, stream.token, transferTo, toWithdraw);
    }

    /// @notice create a stream
    /// @param _token token to stream
    /// @param _to to mint token to
    /// @param _amountPerSec tokens to stream per sec (20 decimals)
    function _createStream(
        address _token,
        address _to,
        uint256 _amountPerSec
    ) private returns (uint256 id) {
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        if (_to == address(0)) revert RECIPIENT_IS_ZERO();

        _update(_token);
        if (block.timestamp > tokens[_token].lastUpdate) revert PAYER_IN_DEBT();

        tokens[_token].totalPaidPerSec += _amountPerSec;

        id = tokenId;
        _safeMint(_to, id);

        streams[id] = Stream({
            amountPerSec: _amountPerSec,
            token: _token,
            paidUpTo: uint96(block.timestamp)
        });

        unchecked {
            tokenId++;
        }
    }

    /// @notice create a stream
    /// @param _token token to stream
    /// @param _to to mint token to
    /// @param _amountPerSec tokens to stream per sec (20 decimals)
    function createStream(
        address _token,
        address _to,
        uint256 _amountPerSec
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec);
        emit CreateStream(id, _token, _to, _amountPerSec);
    }

    /// @notice create stream with withheld event
    /// @param _token token to stream
    /// @param _to to mint token to
    /// @param _amountPerSec tokens to stream per sec (20 decimals)
    /// @param _withheldPerSec withheld per sec for tax withholding (20 decimals)
    function createStreamWithheld(
        address _token,
        address _to,
        uint256 _amountPerSec,
        uint256 _withheldPerSec
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec);
        emit CreateStreamWithheld(
            id,
            _token,
            _to,
            _amountPerSec,
            _withheldPerSec
        );
    }

    /// @notice cancel stream
    /// @param _id token id
    function cancelStream(uint256 _id) external {
        Stream storage stream = streams[_id];
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        if (stream.paidUpTo == 0) revert STREAM_PAUSED_OR_CANCELLED();

        (uint256 withdrawableAmount, , ) = withdrawable(_id);
        (ERC20 token, address transferTo, uint256 toWithdraw) = _withdraw(
            _id,
            withdrawableAmount
        );

        unchecked {
            tokens[stream.token].totalPaidPerSec -= streams[_id].amountPerSec;
        }

        _burn(_id);
        streams[_id] = Stream({
            amountPerSec: 0,
            token: address(0),
            paidUpTo: 0
        });

        token.safeTransfer(transferTo, toWithdraw);
        emit CancelStream(_id);
    }

    /// @notice modify stream
    /// @param _id token id
    /// @param _newAmountPerSec new amount per sec (20 decimals)
    function modifyStream(uint256 _id, uint256 _newAmountPerSec) external {
        Stream storage stream = streams[_id];
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        if (stream.paidUpTo == 0) revert STREAM_PAUSED_OR_CANCELLED();

        (uint256 withdrawableAmount, , ) = withdrawable(_id);
        (ERC20 token, address transferTo, uint256 toWithdraw) = _withdraw(
            _id,
            withdrawableAmount
        );

        unchecked {
            tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
        }

        tokens[stream.token].totalPaidPerSec += _newAmountPerSec;

        token.safeTransfer(transferTo, toWithdraw);
        emit ModifyStream(_id, _newAmountPerSec);
    }

    /// @notice pause stream
    /// @param _id token id
    function pauseStream(uint256 _id) external {
        Stream storage stream = streams[_id];
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        if (stream.paidUpTo == 0) revert STREAM_PAUSED_OR_CANCELLED();

        (uint256 withdrawableAmount, , ) = withdrawable(_id);
        (ERC20 token, address transferTo, uint256 toWithdraw) = _withdraw(
            _id,
            withdrawableAmount
        );

        unchecked {
            tokens[stream.token].totalPaidPerSec -= stream.amountPerSec;
            streams[_id].paidUpTo = 0;
        }

        token.safeTransfer(transferTo, toWithdraw);
        emit PauseStream(_id);
    }

    /// @notice resume stream
    /// @param _id token id
    function resumeStream(uint256 _id) external {
        Stream storage stream = streams[_id];
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        if (ownerOf(_id) == address(0)) revert OWNER_IS_ZERO();
        if (stream.paidUpTo > 0) revert STREAM_ACTIVE();

        _update(stream.token);
        if (block.timestamp > tokens[stream.token].lastUpdate)
            revert PAYER_IN_DEBT();

        streams[_id].paidUpTo = uint96(block.timestamp);
        tokens[stream.token].totalPaidPerSec += stream.amountPerSec;

        emit ResumeStream(_id);
    }

    /// @notice add address to whitelist
    /// @param _toWhitelist address to whitelist
    function approvePayerWhitelist(address _toWhitelist) external {
        if (msg.sender != owner) revert NOT_OWNER();
        payerWhitelists[_toWhitelist] = 1;
    }

    /// @notice remove address from whitelist
    /// @param _toRemove address to remove
    function revokePayerWhitelist(address _toRemove) external {
        if (msg.sender != owner) revert NOT_OWNER();
        payerWhitelists[_toRemove] = 0;
    }

    /// @notice withdrawable from stream
    /// @param _id token id
    /// @return withdrawableAmount wihtdrawable amount (20 decimals)
    function withdrawable(uint256 _id)
        public
        view
        returns (
            uint256 withdrawableAmount,
            uint256 debt,
            uint256 lastPayerUpdate
        )
    {
        Stream storage stream = streams[_id];
        Token storage token = tokens[stream.token];

        uint256 delta = block.timestamp - token.lastUpdate;
        uint256 totalStreamed = delta * token.totalPaidPerSec;
        if (token.balance >= totalStreamed) {
            lastPayerUpdate = block.timestamp;
        } else {
            lastPayerUpdate =
                token.lastUpdate +
                (token.balance / token.totalPaidPerSec);
        }

        uint256 streamDelta = lastPayerUpdate - stream.paidUpTo;
        withdrawableAmount = (streamDelta * stream.amountPerSec);
        debt = (block.timestamp - lastPayerUpdate) * stream.amountPerSec;
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
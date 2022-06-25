/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Registers contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Provides way for users to sign approval for BentoBox spends.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token The ERC-20 token to deposit.
    /// @param from Which account to pull the tokens.
    /// @param to Which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from Which user to pull the tokens.
    /// @param to Which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;
}

/// @title LexLocker
/// @author LexDAO LLC
/// @notice Resolveable, yield-bearing deal escrow for ETH and ERC-20/721 tokens.
contract LexLocker {
    /// @dev BentoBox vault contract.
    IBentoBoxMinimal private immutable bento;
    /// @dev Legal engineering guild.
    address public lexDAO;
    /// @dev Wrapped ether (or native asset) supported on BentoBox.
    address private immutable wETH;
    /// @dev Registered locker counter.
    uint256 public lockerCount;
    /// @dev Chain Id at this contract's deployment.
    uint256 private immutable INITIAL_CHAIN_ID;
    /// @dev EIP-712 typehash for this contract's domain at deployment.
    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR;
    /// @dev EIP-712 typehash for invoicing deposits.
    bytes32 private constant INVOICE_HASH = keccak256("DepositInvoiceSig(address depositor,address receiver,address resolver,string details)");
    /// @dev Convenience marker for contract location.
    string public constant name = "LexLocker";

    /// @dev Stored mappings for users.
    mapping(uint256 => string) public agreements;
    mapping(uint256 => Locker) public lockers;
    mapping(address => Resolver) public resolvers;
    mapping(address => uint256) public lastActionTimestamp;
    
    /// @notice Initialize contract.
    /// @param bento_ BentoBox vault contract.
    /// @param lexDAO_ Legal engineering guild.
    /// @param wETH_ Wrapped ether (or native asset) supported on BentoBox.
    constructor(
        IBentoBoxMinimal bento_, 
        address lexDAO_, 
        address wETH_
    ) payable {
        bento_.registerProtocol();
        bento = bento_;
        lexDAO = lexDAO_;
        wETH = wETH_;
        // set chain init values
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }
    
    /// @dev Events to assist web3 applications.
    event Deposit(
        bool bento,
        bool nft,
        address indexed depositor, 
        address indexed receiver, 
        address indexed resolver,
        address token, 
        uint256 sum,
        uint256 termination,
        uint256 registration,
        string details);
    event Release(uint256 registration);
    event Withdraw(uint256 registration);
    event Lock(uint256 registration, string details);
    event Resolve(uint256 registration, uint256 depositorAward, uint256 receiverAward, string details);
    event RegisterResolver(address indexed resolver, bool active, uint256 fee);
    event RegisterAgreement(uint256 index, string agreement);
    event UpdateLexDAO(address indexed lexDAO);
    
    /// @dev Tracks registered escrow status.
    struct Locker {
        bool bento;
        bool nft; 
        bool locked;
        address depositor;
        address receiver;
        address resolver;
        address token;
        uint32 currentMilestone;
        uint32 termination;
        uint96 paid;
        uint96 sum;
        uint256[] value;
    }
    
    /// @dev Tracks registered resolver status.
    struct Resolver {
        bool active;
        uint8 fee;
    }
    
    /// @dev Ensures registered resolver cooldown.
    modifier cooldown() {
        unchecked {
            require(block.timestamp - lastActionTimestamp[msg.sender] > 8 weeks, "NOT_COOLED_DOWN");
        }
        _;
    }
    
    /// @dev Reentrancy guard.
    uint256 private locked = 1;
    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    /// @dev LexDAO guard.
    modifier onlyLexDAO() {
        require(msg.sender == lexDAO, "NOT_LEXDAO");
        _;
    }
    
    /// @notice EIP-712 typehash for this contract's domain.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }
    
    function computeDomainSeparator() private view returns (bytes32) {
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
    
    // **** ESCROW PROTOCOL **** //
    // ------------------------ //
    
    /// @notice Returns escrow milestone deposits per `value` array.
    /// @param registration The index of escrow deposit.
    function getMilestones(uint256 registration) external view returns (uint256[] memory milestones) {
        milestones = lockers[registration].value;
    }
    
    /// @notice Deposits ETH or tokens (ERC-20/721) into locker 
    /// - escrowed funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlocks funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds in milestones - if `nft`, the 'tokenId' in first value is used.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param details Describes context of escrow - stamped into event.
    function deposit(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool nft, 
        string memory details
    ) public payable nonReentrant returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != receiver, "RESOLVER_CANNOT_BE_PARTY"); // Avoid conflicts.
        
        // Tally up `sum` from `value` milestones.
        uint256 sum;
        for (uint256 i; i < value.length; ) {
            sum += value[i];
            unchecked {
                ++i;
            }
        }
        
        // Handle ETH/ERC-20/721 deposit.
        if (msg.value != 0) {
            require(msg.value == sum, "WRONG_MSG_VALUE");
            // Overrides to clarify ETH is used.
            if (token != address(0)) token = address(0);
            if (nft) nft = false;
        } else {
            safeTransferFrom(token, msg.sender, address(this), sum);
        }

        unchecked {
            registration = lockerCount++;
        }

        lockers[registration] = 
            Locker(
                false, nft, false, msg.sender, receiver, resolver, token, 0, uint32(termination), 0, uint96(sum), value
            );
        
        emit Deposit(false, nft, msg.sender, receiver, resolver, token, sum, termination, registration, details);
    }
    
    /// @notice Deposits ETH or tokens (ERC-20) into BentoBox vault 
    /// - escrowed funds can be released by `msg.sender` `depositor` 
    /// - both parties can {lock} for `resolver`. 
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds (note: NFT not supported in BentoBox).
    /// @param value The amount of funds in milestones (note: locker converts to 'shares').
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    function depositBento(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool wrapBento,
        string memory details
    ) public payable nonReentrant returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != receiver, "RESOLVER_CANNOT_BE_PARTY"); // Avoid conflicts.
        
        // Tally up `sum` from `value` milestones.
        uint256 sum;
        for (uint256 i; i < value.length; ) {
            sum += value[i];
            unchecked {
                ++i;
            }
        }
        
        // Handle ETH/ERC-20 deposit.
        if (msg.value != 0) {
            require(msg.value == sum, "WRONG_MSG_VALUE");
            // Override to clarify wETH is used in BentoBox for ETH.
            if (token != wETH) token = wETH;
            (, sum) = bento.deposit{value: msg.value}(address(0), address(this), address(this), msg.value, 0);
        } else if (wrapBento) {
            safeTransferFrom(token, msg.sender, address(bento), sum);
            (, sum) = bento.deposit(token, address(bento), address(this), sum, 0);
        } else {
            bento.transfer(token, msg.sender, address(this), sum);
        }

        unchecked {
            registration = lockerCount++;
        }

        lockers[registration] = 
            Locker(
                true, false, false, msg.sender, receiver, resolver, token, 0, uint32(termination), 0, uint96(sum), value
            );
  
        emit Deposit(true, false, msg.sender, receiver, resolver, token, sum, termination, registration, details);
    }
    
    /// @notice Validates deposit request 'invoice' for locker escrow.
    /// @param receiver The account that receives funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds in milestones - if `nft`, the 'tokenId'.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param bentoBoxed If 'false', regular deposit is assumed, otherwise, BentoBox.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function depositInvoiceSig(
        address receiver, 
        address resolver, 
        address token, 
        uint256[] memory value,
        uint256 termination,
        bool bentoBoxed,
        bool nft, 
        bool wrapBento,
        string memory details,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        // Validate basic elements of invoice.
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "DepositInvoiceSig(address depositor,address receiver,address resolver,string details)"
                            ),
                            msg.sender,
                            receiver,
                            resolver,
                            details
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == receiver, "INVALID_INVOICE");

        // Perform deposit.
        if (!bentoBoxed) {
            deposit(receiver, resolver, token, value, termination, nft, details);
        } else {
            depositBento(receiver, resolver, token, value, termination, wrapBento, details);
        }
    }
    
    /// @notice Releases escrowed assets to designated `receiver` 
    /// - can only be called by `depositor` if not `locked`
    /// - can be called after `termination` as optional extension
    /// - escrowed sum is released in order of `value` milestones array.
    /// @param registration The index of escrow deposit.
    function release(uint256 registration) external payable nonReentrant {
        Locker storage locker = lockers[registration]; 
        
        require(!locker.locked, "LOCKED");
        require(msg.sender == locker.depositor, "NOT_DEPOSITOR");
        
        uint256 milestone = locker.value[locker.currentMilestone];

        unchecked {
            // Handle asset transfer.
            if (locker.token == address(0)) { // Release ETH.
                safeTransferETH(locker.receiver, milestone);
                locker.paid += uint96(milestone);
                ++locker.currentMilestone;
            } else if (locker.bento) { // Release BentoBox shares.
                bento.transfer(locker.token, address(this), locker.receiver, milestone);
                locker.paid += uint96(milestone);
                ++locker.currentMilestone;
            } else if (!locker.nft) { // ERC-20.
                safeTransfer(locker.token, locker.receiver, milestone);
                locker.paid += uint96(milestone);
                ++locker.currentMilestone;
            } else { // Release NFT (note: set to single milestone).
                safeTransferFrom(locker.token, address(this), locker.receiver, milestone);
                locker.paid += uint96(milestone);
            }
        }
        
        // If remainder paid out or NFT released, delete from storage.
        if (locker.paid == locker.sum) {
            delete lockers[registration];
        }
        
        emit Release(registration);
    }
    
    /// @notice Releases escrowed assets back to designated `depositor` 
    /// - can only be called by `depositor` if `termination` reached.
    /// @param registration The index of escrow deposit.
    function withdraw(uint256 registration) external payable nonReentrant {
        Locker storage locker = lockers[registration];
        
        require(msg.sender == locker.depositor, "NOT_DEPOSITOR");
        require(!locker.locked, "LOCKED");
        require(block.timestamp >= locker.termination, "NOT_TERMINATED");
        
        // Handle asset transfer.
        unchecked {
            if (locker.token == address(0)) { // Release ETH.
                safeTransferETH(locker.depositor, locker.sum - locker.paid);
            } else if (locker.bento) { // Release BentoBox shares.
                bento.transfer(locker.token, address(this), locker.depositor, locker.sum - locker.paid);
            } else if (!locker.nft) { // Release ERC-20.
                safeTransfer(locker.token, locker.depositor, locker.sum - locker.paid);
            } else { // Release NFT.
                safeTransferFrom(locker.token, address(this), locker.depositor, locker.value[0]);
            }
        }
        
        delete lockers[registration];
        
        emit Withdraw(registration);
    }

    // **** DISPUTE PROTOCOL **** //
    // ------------------------- //
    
    /// @notice Locks escrowed assets for resolution - can only be called by locker parties.
    /// @param registration The index of escrow deposit.
    /// @param details Description of lock action (note: can link to secure dispute details, etc.).
    function lock(uint256 registration, string calldata details) external payable {
        Locker storage locker = lockers[registration];
        require(msg.sender == locker.depositor || msg.sender == locker.receiver, "NOT_PARTY");
        locker.locked = true;
        emit Lock(registration, details);
    }
    
    /// @notice Resolves locked escrow deposit in split between parties - if NFT, must be complete award (so, one party receives '0')
    /// - `resolverFee` is automatically deducted from both parties' awards.
    /// @param registration The registration index of escrow deposit.
    /// @param depositorAward The sum given to `depositor`.
    /// @param receiverAward The sum given to `receiver`.
    /// @param details Description of resolution (note: can link to secure judgment details, etc.).
    function resolve(
        uint256 registration, 
        uint256 depositorAward, 
        uint256 receiverAward, 
        string calldata details
    ) external payable nonReentrant {
        Locker storage locker = lockers[registration]; 
        
        uint256 remainder;
        unchecked {
            remainder = locker.sum - locker.paid;
        }
        
        require(msg.sender == locker.resolver, "NOT_RESOLVER");
        require(locker.locked, "NOT_LOCKED");
        require(depositorAward + receiverAward == remainder, "NOT_REMAINDER");

        // Calculate resolution fee from remainder and apply to awards.
        uint256 resolverFee = resolvers[locker.resolver].fee;
        assembly { resolverFee := div(remainder, resolverFee) }
        uint256 feeSplit;
        assembly { feeSplit := div(resolverFee, 2) }
        depositorAward -= feeSplit;
        receiverAward -= feeSplit;

        // Handle asset transfers.
        if (locker.token == address(0)) { // Split ETH.
            safeTransferETH(locker.depositor, depositorAward);
            safeTransferETH(locker.receiver, receiverAward);
            safeTransferETH(locker.resolver, resolverFee);
        } else if (locker.bento) { // ...BentoBox shares.
            bento.transfer(locker.token, address(this), locker.depositor, depositorAward);
            bento.transfer(locker.token, address(this), locker.receiver, receiverAward);
            bento.transfer(locker.token, address(this), locker.resolver, resolverFee);
        } else if (!locker.nft) { // ...ERC20.
            safeTransfer(locker.token, locker.depositor, depositorAward);
            safeTransfer(locker.token, locker.receiver, receiverAward);
            safeTransfer(locker.token, locker.resolver, resolverFee);
        } else { // Award NFT.
            if (depositorAward != 0) {
                safeTransferFrom(locker.token, address(this), locker.depositor, locker.value[0]);
            } else {
                safeTransferFrom(locker.token, address(this), locker.receiver, locker.value[0]);
            }
        }
        
        delete lockers[registration];
        
        emit Resolve(registration, depositorAward, receiverAward, details);
    }
    
    /// @notice Registers an account to serve as a potential `resolver`.
    /// @param active Tracks willingness to serve - if 'true', can be joined to a locker.
    /// @param fee The divisor to determine resolution fee - e.g., if '20', fee is 5% of locker.
    function registerResolver(bool active, uint8 fee) external payable cooldown {
        require(fee != 0, "FEE_MUST_BE_GREATER_THAN_ZERO");
        resolvers[msg.sender] = Resolver(active, fee);
        lastActionTimestamp[msg.sender] = block.timestamp;
        emit RegisterResolver(msg.sender, active, fee);
    }

    // **** LEXDAO PROTOCOL **** //
    // ------------------------ //
    
    /// @notice Registration for LexDAO to maintain agreements that can be stamped into lockers.
    /// @param index # to register agreement under.
    /// @param agreement Text or link to agreement, etc. - this allows for amendments.
    function registerAgreement(uint256 index, string calldata agreement) external payable onlyLexDAO {
        agreements[index] = agreement;
        emit RegisterAgreement(index, agreement);
    }

    /// @notice Action for LexDAO to update role.
    /// @param lexDAO_ Account to assign role to.
    function updateLexDAO(address lexDAO_) external payable onlyLexDAO {
        lexDAO = lexDAO_;
        emit UpdateLexDAO(lexDAO_);
    }

    // **** BATCHER UTILITIES **** //
    // -------------------------- //
    
    /// @notice Enables calling multiple methods in a single call to this contract.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);

        unchecked {
            for (uint256 i; i < data.length; ++i) {
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

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThis(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param deadline Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThisAllowed(
        address token,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, deadline, true, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides way to sign approval for `bento` spends by locker.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function setBentoApproval(uint8 v, bytes32 r, bytes32 s) external payable {
        bento.setMasterContractApproval(msg.sender, address(this), true, v, r, s);
    }
    
    // **** TRANSFER HELPERS **** //
    // ------------------------- //
    
    /// @notice Provides 'safe' ERC-20 {transfer} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20 token.
    /// @param to Account to send tokens to.
    /// @param amount Token amount to send.
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) private {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 15) // Length of the error string.
                mstore(0x44, "TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @notice Provides 'safe' ERC-20/721 {transferFrom} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20/721 token.
    /// @param from Account to send tokens from.
    /// @param to Account to send tokens to.
    /// @param amount Token amount to send - if NFT, 'tokenId'.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 20) // Length of the error string.
                mstore(0x44, "TRANSFER_FROM_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
    
    /// @notice Provides 'safe' ETH transfer.
    /// @param to Account to send ETH to.
    /// @param amount ETH amount to send.
    function safeTransferETH(address to, uint256 amount) private {
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                mstore(0x00, hex"08c379a0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 19) // Length of the error string.
                mstore(0x44, "ETH_TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;



/**

     ██████╗ ██████╗ ███╗   ██╗ ██████╗ █████╗ ██╗   ██╗██████╗
    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██╔══██╗██║   ██║╚════██╗
    ██║     ██║   ██║██╔██╗ ██║██║     ███████║██║   ██║ █████╔╝
    ██║     ██║   ██║██║╚██╗██║██║     ██╔══██║╚██╗ ██╔╝ ╚═══██╗
    ╚██████╗╚██████╔╝██║ ╚████║╚██████╗██║  ██║ ╚████╔╝ ██████╔╝
     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝  ╚═══╝  ╚═════╝

    Concave A Token

*/

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}
/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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
/// @notice Concave A Token
/// @author 0xBarista & Dionysus (ConcaveFi)
contract aCNV is ERC20("Concave A Token (aCNV)", "aCNV", 18) {

    /* ---------------------------------------------------------------------- */
    /*                                DEPENDENCIES                            */
    /* ---------------------------------------------------------------------- */

    using SafeTransferLib for ERC20;

    /* ---------------------------------------------------------------------- */
    /*                             IMMUTABLE STATE                            */
    /* ---------------------------------------------------------------------- */

    /// @notice FRAX tokenIn address
    ERC20 public immutable FRAX = ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    /// @notice DAI tokenIn address
    ERC20 public immutable DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /// @notice Error related to amount
    string constant AMOUNT_ERROR = "!AMOUNT";

    /// @notice Error related to token address
    string constant TOKEN_IN_ERROR = "!TOKEN_IN";

    /// @notice Error minting exceeds supply
    string constant EXCEEDS_SUPPLY = "EXCEEDS_SUPPLY";

    /// @notice Error transfers paused
    string constant PAUSED = "PAUSED";

    /* ---------------------------------------------------------------------- */
    /*                              MUTABLE STATE                             */
    /* ---------------------------------------------------------------------- */

    /// @notice Address that is recipient of raised funds + access control
    address public treasury = 0x226e7AF139a0F34c6771DeB252F9988876ac1Ced;

    /// @notice Returns the current merkle root being used
    bytes32 public merkleRoot;

    /// @notice Returns an array of all merkle roots used
    bytes32[] public roots;

    /// @notice Returns the current pCNV price in DAI/FRAX
    uint256 public rate;

    /// @notice Returns the max supply of pCNV that is allowed to be minted (in total)
    uint256 public maxSupply = 333_000 * 1e18;

    /// @notice Returns the total amount of pCNV that has cumulatively been minted
    uint256 public totalMinted;

    /// @notice Returns whether transfers are paused
    bool public transfersPaused = true;

    /* ---------------------------------------------------------------------- */
    /*                              STRUCTURED STATE                          */
    /* ---------------------------------------------------------------------- */

    /// @notice Structure of Participant vesting storage
    struct Participant {
        uint256 purchased; // amount (in total) of pCNV that user has purchased
        uint256 redeemed;  // amount (in total) of pCNV that user has redeemed
    }

    /// @notice             maps an account to vesting storage
    /// address             - account to check
    /// returns Participant - Structured vesting storage
    mapping(address => Participant) public participants;

    /// @notice             amount of DAI/FRAX user has spent for a specific root
    /// bytes32             - merkle root
    /// address             - account to check
    /// returns uint256     - amount in DAI/FRAX (denominated in ether) spent purchasing pCNV
    mapping(bytes32 => mapping(address => uint256)) public spentAmounts;

    /* ---------------------------------------------------------------------- */
    /*                                  EVENTS                                */
    /* ---------------------------------------------------------------------- */

    /// @notice Emitted when treasury changes treasury address
    /// @param  treasury address of new treasury
    event TreasurySet(address treasury);

    /// @notice             Emitted when a new round is set by treasury
    /// @param  merkleRoot  new merkle root
    /// @param  rate        new price of pCNV in DAI/FRAX
    event NewRound(bytes32 merkleRoot, uint256 rate);

    /// @notice             Emitted when maxSupply of pCNV is burned or minted to target
    /// @param  target      target to which to mint pCNV or burn if target = address(0)
    /// @param  amount      amount of pCNV minted to target or burned
    /// @param  totalMinted amount of pCNV minted to target or burned
    event Managed(address target, uint256 amount, uint256 totalMinted);

    /// @notice                 Emitted when pCNV minted via "mint()" or "mintWithPermit"
    /// @param  depositedFrom   address from which DAI/FRAX was deposited
    /// @param  mintedTo        address to which pCNV were minted to
    /// @param  amount          amount of pCNV minted
    /// @param  deposited       amount of DAI/FRAX deposited
    /// @param  totalMinted     total amount of pCNV minted so far
    event Minted(
        address indexed depositedFrom,
        address indexed mintedTo,
        uint256 amount,
        uint256 deposited,
        uint256 totalMinted
    );

    /// @notice                 Emitted when Concave changes max supply
    /// @param  oldMax          old max supply
    /// @param  newMax          new max supply
    event SupplyChanged(uint256 oldMax, uint256 newMax);

    /* ---------------------------------------------------------------------- */
    /*                                MODIFIERS                               */
    /* ---------------------------------------------------------------------- */

    /// @notice only allows Concave treasury
    modifier onlyConcave() {
        require(msg.sender == treasury, "!CONCAVE");
        _;
    }

    /* ---------------------------------------------------------------------- */
    /*                              ONLY CONCAVE                              */
    /* ---------------------------------------------------------------------- */

    /// @notice Set a new treasury address if treasury
    function setTreasury(
        address _treasury
    ) external onlyConcave {
        treasury = _treasury;
        emit TreasurySet(_treasury);
    }

    /// @notice             Update merkle root and rate
    /// @param _merkleRoot  root of merkle tree
    /// @param _rate        price of pCNV in DAI/FRAX
    function setRound(
        bytes32 _merkleRoot,
        uint256 _rate
    ) external onlyConcave {
        // push new root to array of all roots - for viewing
        roots.push(_merkleRoot);
        // update merkle root
        merkleRoot = _merkleRoot;
        // update rate
        rate = _rate;

        emit NewRound(merkleRoot,rate);
    }

    /// @notice         mint amount to target
    /// @param target   address to which to mint; if address(0), will burn
    /// @param amount   to reduce from max supply or mint to "target"
    function manage(
        address target,
        uint256 amount
    ) external onlyConcave {
        uint256 newAmount = totalMinted + amount;
        require(newAmount <= maxSupply,EXCEEDS_SUPPLY);
        totalMinted = newAmount;
        // mint target amount
        _mint(target, amount);
        emit Managed(target, amount, totalMinted);
    }

    /// @notice             manage max supply
    /// @param _maxSupply   new max supply
    function manageSupply(uint256 _maxSupply) external onlyConcave {
        require(_maxSupply >= totalMinted, "LOWER_THAN_MINT");
        emit SupplyChanged(maxSupply, _maxSupply);
        maxSupply = _maxSupply;
    }

    /// @notice         Allows Concave to pause transfers in the event of a bug
    /// @param paused   if transfers should be paused or not
    function setTransfersPaused(bool paused) external onlyConcave {
        transfersPaused = paused;
    }

    /* ---------------------------------------------------------------------- */
    /*                              PUBLIC LOGIC                              */
    /* ---------------------------------------------------------------------- */

    /// @notice               mint pCNV by providing merkle proof and depositing DAI/FRAX
    /// @param to             whitelisted address pCNV will be minted to
    /// @param tokenIn        address of tokenIn user wishes to deposit (DAI/FRAX)
    /// @param maxAmount      max amount of DAI/FRAX sender can deposit for pCNV, to verify merkle proof
    /// @param amountIn       amount of DAI/FRAX sender wishes to deposit for pCNV
    /// @param proof          merkle proof to prove "to" and "maxAmount" are in merkle tree
    function mint(
        address to,
        address tokenIn,
        uint256 maxAmount,
        uint256 amountIn,
        bytes32[] calldata proof
    ) external returns (uint256 amountOut) {
        return _purchase(msg.sender, to, tokenIn, maxAmount, amountIn, proof);
    }

    /// @notice               mint pCNV by providing merkle proof and depositing DAI; uses EIP-2612 permit to save a transaction
    /// @param to             whitelisted address pCNV will be minted to
    /// @param tokenIn        address of tokenIn user wishes to deposit (DAI)
    /// @param maxAmount      max amount of DAI sender can deposit for pCNV, to verify merkle proof
    /// @param amountIn       amount of DAI sender wishes to deposit for pCNV
    /// @param proof          merkle proof to prove "to" and "maxAmount" are in merkle tree
    /// @param permitDeadline EIP-2612 : time when permit is no longer valid
    /// @param v              EIP-2612 : part of EIP-2612 signature
    /// @param r              EIP-2612 : part of EIP-2612 signature
    /// @param s              EIP-2612 : part of EIP-2612 signature
    function mintWithPermit(
        address to,
        address tokenIn,
        uint256 maxAmount,
        uint256 amountIn,
        bytes32[] calldata proof,
        uint256 permitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountOut) {
        // Make sure payment tokenIn is DAI
        require(tokenIn == address(DAI), TOKEN_IN_ERROR);
        // Approve tokens for spender - https://eips.ethereum.org/EIPS/eip-2612
        ERC20(tokenIn).permit(msg.sender, address(this), amountIn, permitDeadline, v, r, s);
        // allow sender to mint for "to"
        return _purchase(msg.sender, to, tokenIn, maxAmount, amountIn, proof);
    }

    /// @notice         transfer "amount" of tokens from msg.sender to "to"
    /// @dev            calls "_beforeTransfer" to update vesting storage for "from" and "to"
    /// @param to       address tokens are being sent to
    /// @param amount   number of tokens being transfered
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!transfersPaused,PAUSED);
        // default ERC20 transfer
        return super.transfer(to, amount);
    }

    /// @notice         transfer "amount" of tokens from "from" to "to"
    /// @dev            calls "_beforeTransfer" to update vesting storage for "from" and "to"
    /// @param from     address tokens are being transfered from
    /// @param to       address tokens are being sent to
    /// @param amount   number of tokens being transfered
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!transfersPaused,PAUSED);
        // default ERC20 transfer
        return super.transferFrom(from, to, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                             INTERNAL LOGIC                             */
    /* ---------------------------------------------------------------------- */

    /// @notice               Deposits FRAX/DAI for pCNV if merkle proof exists in specified round
    /// @param sender         address sending transaction
    /// @param to             whitelisted address purchased pCNV will be sent to
    /// @param tokenIn        address of tokenIn user wishes to deposit
    /// @param maxAmount      max amount of DAI/FRAX sender can deposit for pCNV
    /// @param amountIn       amount of DAI/FRAX sender wishes to deposit for pCNV
    /// @param proof          merkle proof to prove address and amount are in tree
    function _purchase(
        address sender,
        address to,
        address tokenIn,
        uint256 maxAmount,
        uint256 amountIn,
        bytes32[] calldata proof
    ) internal returns(uint256 amountOut) {
        // Make sure payment tokenIn is either DAI or FRAX
        require(tokenIn == address(DAI) || tokenIn == address(FRAX), TOKEN_IN_ERROR);

        // Require merkle proof with `to` and `maxAmount` to be successfully verified
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(to, maxAmount))), "!PROOF");

        // Verify amount claimed by user does not surpass "maxAmount"
        uint256 newAmount = spentAmounts[merkleRoot][to] + amountIn; // save gas
        require(newAmount <= maxAmount, AMOUNT_ERROR);
        spentAmounts[merkleRoot][to] = newAmount;

        // Calculate rate of pCNV that should be returned for "amountIn"
        amountOut = amountIn * 1e18 / rate;

        // make sure total minted + amount is less than or equal to maximum supply
        require(totalMinted + amountOut <= maxSupply, EXCEEDS_SUPPLY);

        // Interface storage for participant
        Participant storage participant = participants[to];

        // Increase participant.purchased to account for newly purchased tokens
        participant.purchased += amountOut;

        // Increase totalMinted to account for newly minted supply
        totalMinted += amountOut;

        // Transfer amountIn*ratio of tokenIn to treasury address
        ERC20(tokenIn).safeTransferFrom(sender, treasury, amountIn);

        // Mint tokens to address after pulling
        _mint(to, amountOut);

        emit Minted(sender, to, amountOut, amountIn, totalMinted);
    }

    /// @notice         Rescues accidentally sent tokens and ETH
    /// @param token    address of token to rescue, if address(0) rescue ETH
    function rescue(address token) external onlyConcave {
        if (token == address(0)) payable(treasury).transfer( address(this).balance );
        else ERC20(token).transfer(treasury, ERC20(token).balanceOf(address(this)));
    }
}

/**

    "someone spent a lot of computational power and time to bruteforce that contract address
    so basically to have that many leading zeros
    you can't just create a contract and get that, the odds are 1 in trillions to get something like that
    there's a way to guess which contract address you will get, using a script.. and you have to bruteforce for a very long time to get that many leading 0's
    fun fact, the more leading 0's a contract has, the cheaper gas will be for users to interact with the contract"

        - some solidity dev

    © 2022 WTFPL – Do What the Fuck You Want to Public License.
*/
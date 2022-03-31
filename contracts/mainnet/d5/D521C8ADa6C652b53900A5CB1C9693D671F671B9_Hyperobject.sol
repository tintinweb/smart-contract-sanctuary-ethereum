/// Luxury rap, the Hermés of verses
/// Sophisticated ignorance, write my curses in cursive
/// I get it custom, you a customer
/// You ain't accustomed to going through customs, you ain't been nowhere, huh?

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Exchange.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";

/// @title Cryptomedia
/// @author neuroswish
/// @notice NFT with an autonomous exchange

contract Hyperobject is ERC721 {

    // ======== Storage ========

    address public exchange; // Exchange token pair address
    address public immutable factory; // Pair factory address
    string public baseURI; // NFT base URI
    uint256 currentTokenId; // Counter keeping track of last minted token id

    // ======== Errors ========

	/// @notice Thrown when function caller is unauthorized
	error Unauthorized();

	/// @notice Thrown when transfer recipient is invalid
	error InvalidRecipient();

    /// @notice Thrown when token id is invalid
	error InvalidTokenId();

    // ======== Constructor ========

    /// @notice Set factory address
    /// @param _factory Factory address
    constructor(address _factory) ERC721("Verse", "VERSE") {
        factory = _factory;
     }

    // ======== Initializer ========

    /// @notice Initialize a new exchange
    /// @param _name Hyperobject name
    /// @param _symbol Hyperobject symbol
    /// @param _baseURI Token base URI
    /// @param _exchange Exchange address
    /// @dev Called by factory at time of deployment
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        address _exchange
    ) external {
        if (msg.sender != factory) revert Unauthorized();
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        exchange = _exchange;
        currentTokenId++;
    }

    // ======== Functions ========

    /// @notice Mint NFT
    /// @param _recipient NFT recipient
    /// @dev Increments currentTokenId
    function mint(address _recipient) external {
        if (msg.sender != exchange) revert Unauthorized();
        if (_recipient == address(0)) revert InvalidRecipient();
        _mint(_recipient, currentTokenId++);
    }

    /// @notice Retrieve token URI for specified NFT
    /// @param _tokenId Token id
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (ownerOf[_tokenId] == address(0)) revert InvalidTokenId();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

}

/// I just needed time alone with my own thoughts
/// Got treasures in my mind, but couldn't open up my own vault
/// My childlike creativity, purity, and honesty
/// Is honestly being crowded by these grown thoughts

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./interfaces/IBondingCurve.sol";
import "./interfaces/IHyperobject.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/// @title Exchange
/// @author neuroswish
/// @notice Autonomous exchange for hyperobjects

contract Exchange is ERC20, ReentrancyGuard {

    // ======== Storage ========

    address public immutable factory; // Exchange factory address
    address public immutable bondingCurve; // Bonding curve address
    address public creator; // Hyperobject creator
    address public hyperobject; // Hyperobject address
    uint256 public reserveRatio; // Reserve ratio of token market cap to ETH pool
    uint256 public slopeInit; // Slope value to initialize supply
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public transactionShare; // Transaction share

    // ======== Errors ========

	/// @notice Thrown when function caller is unauthorized
	error Unauthorized();

	/// @notice Thrown when token or ETH input is invalid
	error InvalidValue();

    /// @notice Thrown when slippage input is invalid
	error InvalidSlippage();

    /// @notice Thrown when initial price input is insufficient
	error InsufficientInitialPrice();

    /// @notice Thrown when slippage occurs
	error Slippage();

    /// @notice Thrown when sell amount is invalid
	error InvalidSellAmount();

    /// @notice Thrown when user balance is insufficient
	error InsufficientBalance();

    /// @notice Thrown when pool balance is insufficient
	error InsufficientPoolBalance();

    // ======== Events ========

    /// @notice Emitted when tokens are purchased
	/// @param buyer Token buyer
    /// @param poolBalance Pool balance
    /// @param totalSupply Total supply
    /// @param tokens Tokens bought
    /// @param price ETH
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );

    /// @notice Emitted when tokens are sold
	/// @param seller Token seller
    /// @param poolBalance Pool balance
    /// @param totalSupply Total supply
    /// @param tokens Tokens sold
    /// @param eth ETH
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );

    /// @notice Emitted when tokens are sold
	/// @param redeemer Token redeemer
    event Redeem(
        address indexed redeemer
    );

    // ======== Constructor ========

    /// @notice Set factory and bonding curve addresses
    /// @param _factory Factory address
    /// @param _bondingCurve Bonding curve address
    constructor(address _factory, address _bondingCurve) ERC20("Verse", "VERSE", 18) {
        factory = _factory;
        bondingCurve = _bondingCurve;
    }

    // ======== Initializer ========

    /// @notice Initialize a new exchange
    /// @param _name Hyperobject name
    /// @param _symbol Hyperobject symbol
    /// @param _reserveRatio Reserve ratio
    /// @param _slopeInit Initial slope value to determine price curve
    /// @param _transactionShare Transaction share
    /// @param _hyperobject Hyperobject address
    /// @param _creator Hyperobject creator
    /// @dev Called by factory at time of deployment
    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint256 _reserveRatio,
        uint256 _slopeInit,
        uint256 _transactionShare,
        address _hyperobject,
        address _creator
    ) external {
        if (msg.sender != factory) revert Unauthorized();
        name = _name;
        symbol = _symbol;
        reserveRatio = _reserveRatio;
        slopeInit = _slopeInit;
        transactionShare = _transactionShare;
        hyperobject = _hyperobject;
        creator = _creator;
    }

    // ======== Functions ========

    /// @notice Buy tokens with ETH
    /// @param _minTokensReturned Minimum tokens returned in case of slippage
    /// @dev Emits a Buy event upon success; callable by anyone
    function buy(uint256 _minTokensReturned) external payable {
        if (msg.value == 0) revert InvalidValue();
        if (_minTokensReturned == 0) revert InvalidSlippage();
        uint256 price = msg.value;
        uint256 creatorShare = splitShare(price);
        uint256 buyAmount = price - creatorShare;
        uint256 tokensReturned;
        if (totalSupply == 0 || poolBalance == 0) {
            if (buyAmount < 1 * (10**15)) revert InsufficientInitialPrice();
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(buyAmount / (10**15), reserveRatio, slopeInit);
            tokensReturned = tokensReturned * (10**15);
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    buyAmount
                );
        }
        if (tokensReturned < _minTokensReturned) revert Slippage();
        _mint(msg.sender, tokensReturned);
        poolBalance += buyAmount;
        SafeTransferLib.safeTransferETH(payable(creator), creatorShare);
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, buyAmount);
    }

    /// @notice Sell market tokens for ETH
    /// @param _tokens Tokens to sell
    /// @param _minETHReturned Minimum ETH returned in case of slippage
    /// @dev Emits a Sell event upon success; callable by token holders
    function sell(uint256 _tokens, uint256 _minETHReturned)
        external
    {
        if (_tokens == 0) revert InvalidSellAmount();
        if (_tokens > balanceOf[msg.sender]) revert InsufficientBalance();
        if (poolBalance == 0) revert InsufficientPoolBalance();
        if (_minETHReturned == 0) revert InvalidSlippage();
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        uint256 creatorShare = splitShare(ethReturned);
        uint256 sellerShare = ethReturned - creatorShare;
        if (sellerShare < _minETHReturned) revert Slippage();
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        SafeTransferLib.safeTransferETH(payable(msg.sender), sellerShare);
        SafeTransferLib.safeTransferETH(payable(creator), creatorShare);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    
    /// @notice Redeem ERC20 token for Hyperobject NFT
    /// @dev Mints NFT from Hyperobject contract for caller upon success; callable by token holders with at least 1 token
    function redeem() public {
        if (balanceOf[msg.sender] < (1 * (10**18))) revert InsufficientBalance();
        transfer(hyperobject, (1 * (10**18)));
        IHyperobject(hyperobject).mint(msg.sender);
        emit Redeem(msg.sender);
    }

    // ======== Utility Functions ========

    /// @notice Calculate share of ETH that goes to creator for each transaction
    /// @param _amount Amount to split
    /// @dev Calculates share based on 10000 basis points; called internally
    function splitShare(uint256 _amount) internal view returns (uint256 _share) {
        _share = (_amount * transactionShare) / 10000;
    }
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBondingCurve {
    function calculateInitializationReturn(uint256 _price, uint256 _reserveRatio, uint256 _slopeInit)
        external
        view
        returns (uint256);

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _price
    ) external returns (uint256);
    
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _reserveRatio,
        uint256 _tokens
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IHyperobject {
    function mint(address _recipient) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

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
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";
import {LogisticVRGDA} from "./LogisticVRGDA.sol";

/// @title Logistic To Linear Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a piecewise logistic and linear issuance curve.
abstract contract LogisticToLinearVRGDA is LogisticVRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The number of tokens that must be sold for the switch to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable soldBySwitch;

    /// @dev The time soldBySwitch tokens were targeted to sell by.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable switchTime;

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perTimeUnit;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _logisticAsymptote The asymptote (minus 1) of the pre-switch logistic curve, scaled by 1e18.
    /// @param _timeScale The steepness of the pre-switch logistic curve, scaled by 1e18.
    /// @param _soldBySwitch The number of tokens that must be sold for the switch to occur.
    /// @param _switchTime The time soldBySwitch tokens were targeted to sell by, scaled by 1e18.
    /// @param _perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _logisticAsymptote,
        int256 _timeScale,
        int256 _soldBySwitch,
        int256 _switchTime,
        int256 _perTimeUnit
    ) LogisticVRGDA(_targetPrice, _priceDecayPercent, _logisticAsymptote, _timeScale) {
        soldBySwitch = _soldBySwitch;

        switchTime = _switchTime;

        perTimeUnit = _perTimeUnit;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        // If we've not yet reached the number of sales required for the switch
        // to occur, we'll continue using the standard logistic VRGDA schedule.
        if (sold < soldBySwitch) return LogisticVRGDA.getTargetSaleTime(sold);

        unchecked {
            return unsafeWadDiv(sold - soldBySwitch, perTimeUnit) + switchTime;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadLn, unsafeDiv, unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The maximum number of tokens of tokens to sell + 1. We add
    /// 1 because the logistic function will never fully reach its limit.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable logisticLimit;

    /// @dev The maximum number of tokens of tokens to sell + 1 multiplied
    /// by 2. We could compute it on the fly each time but this saves gas.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 internal immutable logisticLimitDoubled;

    /// @dev Time scale controls the steepness of the logistic curve,
    /// which affects how quickly we will reach the curve's asymptote.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable timeScale;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _maxSellable The maximum number of tokens to sell, scaled by 1e18.
    /// @param _timeScale The steepness of the logistic curve, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _maxSellable,
        int256 _timeScale
    ) VRGDA(_targetPrice, _priceDecayPercent) {
        // Add 1 wad to make the limit inclusive of _maxSellable.
        logisticLimit = _maxSellable + 1e18;

        // Scale by 2e18 to both double it and give it 36 decimals.
        logisticLimitDoubled = logisticLimit * 2e18;

        timeScale = _timeScale;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimitDoubled, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    constructor(int256 _targetPrice, int256 _priceDecayPercent) {
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1))
            ))));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title GOO (Gradual Ownership Optimization) Issuance
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Implementation of the GOO Issuance mechanism.
library LibGOO {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and time elapsed.
    /// @param emissionMultiple The multiple on emissions to consider when computing the balance.
    /// @param lastBalanceWad The last checkpointed balance to apply the emission multiple over time to, scaled by 1e18.
    /// @param timeElapsedWad The time elapsed since the last checkpoint, scaled by 1e18.
    function computeGOOBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            // We use wad math here because timeElapsedWad is, as the name indicates, a wad.
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
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

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*                                                                              **,/*,
                                                                     *%@&%#/*,,..........,/(%&@@#*
                                                                 %@%,..............................#@@%
                                                              &&,.....,,...............................,/&@*
                                                            (@*.....**............,/,.......................(@%
                                                           &&......*,............./,.............**............&@
                                                          @#......**.............**..............,*........,*,..,@/
                                                         /@......,/............../,..............,*........../,..*@.
                                                        #@,......................*.............../,..........**...#/
                                                      ,@&,.......................................*..........,/....(@
                                                  *@&(*...................................................../*....(@
                                                 @(..*%@@&%#(#@@@%%%%%&&@@@@@@@@@&&#(///..........................#@
                                                 @%/@@@&%&&&@@&%%%%%%%#(/(((/(/(/(/(/(/(/(/(%%&@@@%(/,............#&
                                                  @@@#/**./@%%%&%#/*************./(%@@@@&(*********(@&&@@@%(.....,&@
                                                 ,@/.//(&@@/.     .#@%/******./&&*,      ./@&********%@/**(@#@@#,..(@
                                                 #%****%@.           %@/****./&@      ,.    %&********%@(**&@...(@#.#@
                                                 &#**./@/  %@&&      [email protected]#****./@*    &@@@@&  [email protected]/******./@@((((@&....(@
                                                 ##**./&@ ,&@@@,     #@/****./@@      @@.  [email protected]&*******./@%****%@@@(,
                                                 ,@/**./%@(.      .*@@/********(&@#*,,,,/&@%/*******./@@&&&@@@#
                                                   @&/**@&/%&&&&&%/**.//////*********./************./@&******@*
                                                     /@@@@&(////#%&@@&(**./#&@@&(//*************./&@(********#@
                                                       [email protected]#**.///*****************(#@@@&&&&&@@@@&%(**********./@,
                                                       @(*****%@#*********************&@#*********************(@
                                                       @****./@#*./@@#//***.///(%@%*****%@*********************#@
                                                      #&****./@%************************&@**********************@%
                                                     [email protected]/******.//*******************./@@(************************@/
                                                     /@**********************************************************(@,
                                                     @#*****************************************************%@@@@@@@.
                                                    *@/*************************************************************#@(
                                                    @%***************************************************************./@(
                     /@@&&&@@                     [email protected]/*******************************************************************&@
                    @%######%@.                   @#***************************./%&&&%(**************#%******************&#
                    @%######&@%&@@.             ,@(***./&#********************#@&#####%@&*************&%****************./@,
               &&*,/@%######&@@@*.*@&,         @@****./@&*******************./%@#######%@#***********./@&*****************(@
              ((...*%@&##%@@,..........,,,,%@&@%/*****&%****************./&@#*%@#######&@*#@%*********./@&*****************(@,
              (@#....(@%#&&,...,/[email protected](*******(@(****************(@/...*%@@@@@@%*....&@@@@&@@@@@@%/%@@##(************(@.
              ((./(((%@%#&@/,/&@/...........%&*******%@****************./@%,.................#,............/@%***************#@
              *@@####@@%###%&@(@(...........%&*******%@****************%@,,#%/..............................#@/***************&/
              (#.....,&&####&@..%%..........%%*****(@@#****************#@,[email protected](***************(@
              [email protected]@&%%&@@&####&&.............,@(***%@(**********./#%%%%%##&@&#(,...............................#@****************&.
               &#.....(@%###&@*............%@**%@(*******(&@&%#/////////@%...................................#@***************&@
                 #@@@@&%####&@&&&,........%@./@%*****(@@%////////////////@@@%,...............................#@**************#@
                     @@&&&&@@(    /&@@&%%@&@@@%**./&@(///////////////////@%.................................,@(*********./%@&.
                      (@//@%                @%***&&(//////////////////////(&@(**,,,,./(%&@@@%/*,,****,,***./@@&&&&&&&&#//%@
                      (@//%@               (@(*#@#////////////////////////////%@@%%%&@@#////%@/***************************&&
                      (@//%@  .,,,,/#&&&&&&@&*#@#///////////////////////////////@%//&&///////#@(***************************@&(#@@@@@&(*.
               ,@@@@@&&@//%@,,.,,,,,.,..,,#@./@%////////////////////////////////%@**&&////////(@(**************************&#,,,,,,,,,,,,/(#&@&
          &@%*,,,,,,,,#@//%@,,,,,,,,,,,,,,&%*#@(////////////////////////////////%@**&&/////////&@**************************#@.,,,.,,.,,&#.,,...,%@
       (@/,,,,,,,,,,,,(@(/%@,,,,,,,,,,,,,,&%*#@(////////////////////////////////%@./%@/////////#@(*************************&%,,,(%@@@@#*,.     .,/@.
      &%..    *&@%/,.,#@(*#@*,,.,,,,,,,,,,%@/#@(////////////////////////////////%@**#@/////////#@(*****************.//#%@@@@%%(/,...        ...,,,%&
     ,@*.,.       ../((%&&@@@&%#((///,,,,,/@&(@(////////////////////////////////@&**#@/////////%@%###%&&&&@@@@@@%%#(**,,,,,,.         ..,,,,,,,,,,%#
      @(,,,,,..,            ,..   ..,,,**(%%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%(((,,.,.,,,,,,.,..,,,,.,.,,,,.,..,.,,.,,,,,.,,,,,,,,,.*@%
       @%,,,,,,,,,,,,,,,.,.,,,      .,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,.,,,,,,#@@,
        ,@@(,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,.,,.,.,./#%&@@@@@#
         [email protected]#&@@@@@%*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/&@@@@@%&@%((((#@@.
          [email protected]%((((#@@@/#&@@@@&%#/*,.,..,,,,.,,,,,.,.,,,,,,,,,,,,,,,,..,.,..,,...,,,...,,,,,,.,,,,,,,,,,,../#%&@@@@@@@&%((///*********./(((/&&
             %@&%%#/***********./////(((((((####%%&&@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@&&%%%%%%%%#((((((((%@&#(((((#%@%/*******************./*/

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LibGOO} from "goo-issuance/LibGOO.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {RandProvider} from "./utils/rand/RandProvider.sol";
import {GobblersERC721} from "./utils/token/GobblersERC721.sol";

import {Goo} from "./Goo.sol";
import {Pages} from "./Pages.sol";

/// @title Art Gobblers NFT
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice An experimental decentralized art factory by Justin Roiland and Paradigm.
contract ArtGobblers is GobblersERC721, LogisticVRGDA, Owned, ERC1155TokenReceiver {
    using LibString for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address of the Pages ERC721 token contract.
    Pages public immutable pages;

    /// @notice The address which receives gobblers reserved for the team.
    address public immutable team;

    /// @notice The address which receives gobblers reserved for the community.
    address public immutable community;

    /// @notice The address of a randomness provider. This provider will initially be
    /// a wrapper around Chainlink VRF v1, but can be changed in case it is fully sunset.
    RandProvider public randProvider;

    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable gobblers.
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Maximum amount of gobblers mintable via mintlist.
    uint256 public constant MINTLIST_SUPPLY = 2000;

    /// @notice Maximum amount of mintable legendary gobblers.
    uint256 public constant LEGENDARY_SUPPLY = 10;

    /// @notice Maximum amount of gobblers split between the reserves.
    /// @dev Set to comprise 20% of the sum of goo mintable gobblers + reserved gobblers.
    uint256 public constant RESERVED_SUPPLY = (MAX_SUPPLY - MINTLIST_SUPPLY - LEGENDARY_SUPPLY) / 5;

    /// @notice Maximum amount of gobblers that can be minted via VRGDA.
    // prettier-ignore
    uint256 public constant MAX_MINTABLE = MAX_SUPPLY
        - MINTLIST_SUPPLY
        - LEGENDARY_SUPPLY
        - RESERVED_SUPPLY;

    /*//////////////////////////////////////////////////////////////
                           METADATA CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Provenance hash for gobbler metadata.
    bytes32 public immutable PROVENANCE_HASH;

    /// @notice URI for gobblers pending reveal.
    string public UNREVEALED_URI;

    /// @notice Base URI for minted gobblers.
    string public BASE_URI;

    /*//////////////////////////////////////////////////////////////
                             MINTLIST STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Merkle root of mint mintlist.
    bytes32 public immutable merkleRoot;

    /// @notice Mapping to keep track of which addresses have claimed from mintlist.
    mapping(address => bool) public hasClaimedMintlistGobbler;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of minting.
    uint256 public immutable mintStart;

    /// @notice Number of gobblers minted from goo.
    uint128 public numMintedFromGoo;

    /*//////////////////////////////////////////////////////////////
                         STANDARD GOBBLER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of the most recently minted non legendary gobbler.
    /// @dev Will be 0 if no non legendary gobblers have been minted yet.
    uint128 public currentNonLegendaryId;

    /// @notice The number of gobblers minted to the reserves.
    uint256 public numMintedForReserves;

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Initial legendary gobbler auction price.
    uint256 public constant LEGENDARY_GOBBLER_INITIAL_START_PRICE = 69;

    /// @notice The last LEGENDARY_SUPPLY ids are reserved for legendary gobblers.
    uint256 public constant FIRST_LEGENDARY_GOBBLER_ID = MAX_SUPPLY - LEGENDARY_SUPPLY + 1;

    /// @notice Legendary auctions begin each time a multiple of these many gobblers have been minted from goo.
    /// @dev We add 1 to LEGENDARY_SUPPLY because legendary auctions begin only after the first interval.
    uint256 public constant LEGENDARY_AUCTION_INTERVAL = MAX_MINTABLE / (LEGENDARY_SUPPLY + 1);

    /// @notice Struct holding data required for legendary gobbler auctions.
    struct LegendaryGobblerAuctionData {
        // Start price of current legendary gobbler auction.
        uint128 startPrice;
        // Number of legendary gobblers sold so far.
        uint128 numSold;
    }

    /// @notice Data about the current legendary gobbler auction.
    LegendaryGobblerAuctionData public legendaryGobblerAuctionData;

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding data required for gobbler reveals.
    struct GobblerRevealsData {
        // Last randomness obtained from the rand provider.
        uint64 randomSeed;
        // Next reveal cannot happen before this timestamp.
        uint64 nextRevealTimestamp;
        // Id of latest gobbler which has been revealed so far.
        uint64 lastRevealedId;
        // Remaining gobblers to be revealed with the current seed.
        uint56 toBeRevealed;
        // Whether we are waiting to receive a seed from the provider.
        bool waitingForSeed;
    }

    /// @notice Data about the current state of gobbler reveals.
    GobblerRevealsData public gobblerRevealsData;

    /*//////////////////////////////////////////////////////////////
                            GOBBLED ART STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps gobbler ids to NFT contracts and their ids to the # of those NFT ids gobbled by the gobbler.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public getCopiesOfArtGobbledByGobbler;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);

    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);

    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event RandProviderUpgraded(address indexed user, RandProvider indexed newRandProvider);

    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);

    event ArtGobbled(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidProof();
    error AlreadyClaimed();
    error MintStartPending();

    error SeedPending();
    error RevealsPending();
    error RequestTooEarly();
    error ZeroToBeRevealed();
    error NotRandProvider();

    error ReserveImbalance();

    error Cannibalism();
    error OwnerMismatch(address owner);

    error NoRemainingLegendaryGobblers();
    error CannotBurnLegendary(uint256 gobblerId);
    error InsufficientGobblerAmount(uint256 cost);
    error LegendaryAuctionNotStarted(uint256 gobblersLeft);

    error PriceExceededMax(uint256 currentPrice);

    error NotEnoughRemainingToBeRevealed(uint256 totalRemainingToBeRevealed);

    error UnauthorizedCaller(address caller);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint config, relevant addresses, and URIs.
    /// @param _merkleRoot Merkle root of mint mintlist.
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _goo Address of the Goo contract.
    /// @param _team Address of the team reserve.
    /// @param _community Address of the community reserve.
    /// @param _randProvider Address of the randomness provider.
    /// @param _baseUri Base URI for revealed gobblers.
    /// @param _unrevealedUri URI for unrevealed gobblers.
    /// @param _provenanceHash Provenance Hash for gobbler metadata.
    constructor(
        // Mint config:
        bytes32 _merkleRoot,
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        Pages _pages,
        address _team,
        address _community,
        RandProvider _randProvider,
        // URIs:
        string memory _baseUri,
        string memory _unrevealedUri,
        // Provenance:
        bytes32 _provenanceHash
    )
        GobblersERC721("Art Gobblers", "GOBBLER")
        Owned(msg.sender)
        LogisticVRGDA(
            69.42e18, // Target price.
            0.31e18, // Price decay percent.
            // Max gobblers mintable via VRGDA.
            toWadUnsafe(MAX_MINTABLE),
            0.0023e18 // Time scale.
        )
    {
        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        goo = _goo;
        pages = _pages;
        team = _team;
        community = _community;
        randProvider = _randProvider;

        BASE_URI = _baseUri;
        UNREVEALED_URI = _unrevealedUri;

        PROVENANCE_HASH = _provenanceHash;

        // Set the starting price for the first legendary gobbler auction.
        legendaryGobblerAuctionData.startPrice = uint128(LEGENDARY_GOBBLER_INITIAL_START_PRICE);

        // Reveal for initial mint must wait a day from the start of the mint.
        gobblerRevealsData.nextRevealTimestamp = uint64(_mintStart + 1 days);
    }

    /*//////////////////////////////////////////////////////////////
                          MINTLIST CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim from mintlist, using a merkle proof.
    /// @dev Function does not directly enforce the MINTLIST_SUPPLY limit for gas efficiency. The
    /// limit is enforced during the creation of the merkle proof, which will be shared publicly.
    /// @param proof Merkle proof to verify the sender is mintlisted.
    /// @return gobblerId The id of the gobbler that was claimed.
    function claimGobbler(bytes32[] calldata proof) external returns (uint256 gobblerId) {
        // If minting has not yet begun, revert.
        if (mintStart > block.timestamp) revert MintStartPending();

        // If the user has already claimed, revert.
        if (hasClaimedMintlistGobbler[msg.sender]) revert AlreadyClaimed();

        // If the user's proof is invalid, revert.
        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        hasClaimedMintlistGobbler[msg.sender] = true;

        unchecked {
            // Overflow should be impossible due to supply cap of 10,000.
            emit GobblerClaimed(msg.sender, gobblerId = ++currentNonLegendaryId);
        }

        _mint(msg.sender, gobblerId);
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a gobbler, paying with goo.
    /// @param maxPrice Maximum price to pay to mint the gobbler.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual goo balance, or from their ERC20 goo balance.
    /// @return gobblerId The id of the gobbler that was minted.
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 gobblerId) {
        // No need to check if we're at MAX_MINTABLE,
        // gobblerPrice() will revert once we reach it due to its
        // logistic nature. It will also revert prior to the mint start.
        uint256 currentPrice = gobblerPrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's goo balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance
            ? updateUserGooBalance(msg.sender, currentPrice, GooBalanceUpdateType.DECREASE)
            : goo.burnForGobblers(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromGoo; // Overflow should be impossible due to the supply cap.

            emit GobblerPurchased(msg.sender, gobblerId = ++currentNonLegendaryId, currentPrice);
        }

        _mint(msg.sender, gobblerId);
    }

    /// @notice Gobbler pricing in terms of goo.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    /// @return Current price of a gobbler in terms of goo.
    function gobblerPrice() public view returns (uint256) {
        // We need checked math here to cause underflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), numMintedFromGoo);
    }

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a legendary gobbler by burning multiple standard gobblers.
    /// @param gobblerIds The ids of the standard gobblers to burn.
    /// @return gobblerId The id of the legendary gobbler that was minted.
    function mintLegendaryGobbler(uint256[] calldata gobblerIds) external returns (uint256 gobblerId) {
        // Get the number of legendary gobblers sold up until this point.
        uint256 numSold = legendaryGobblerAuctionData.numSold;

        gobblerId = FIRST_LEGENDARY_GOBBLER_ID + numSold; // Assign id.

        // This will revert if the auction hasn't started yet or legendaries
        // have sold out entirely, so there is no need to check here as well.
        uint256 cost = legendaryGobblerPrice();

        if (gobblerIds.length < cost) revert InsufficientGobblerAmount(cost);

        // Overflow should not occur in here, as most math is on emission multiples, which are inherently small.
        unchecked {
            uint256 burnedMultipleTotal; // The legendary's emissionMultiple will be 2x the sum of the gobblers burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < cost; ++i) {
                id = gobblerIds[i];

                if (id >= FIRST_LEGENDARY_GOBBLER_ID) revert CannotBurnLegendary(id);

                GobblerData storage gobbler = getGobblerData[id];

                require(gobbler.owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += gobbler.emissionMultiple;

                delete getApproved[id];

                emit Transfer(msg.sender, gobbler.owner = address(0), id);
            }

            /*//////////////////////////////////////////////////////////////
                                 LEGENDARY MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // The legendary's emissionMultiple is 2x the sum of the multiples of the gobblers burned.
            getGobblerData[gobblerId].emissionMultiple = uint32(burnedMultipleTotal * 2);

            // Update the user's user data struct in one big batch. We add burnedMultipleTotal to their
            // emission multiple (not burnedMultipleTotal * 2) to account for the standard gobblers that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getUserData[msg.sender].lastBalance = uint128(gooBalance(msg.sender)); // Checkpoint balance.
            getUserData[msg.sender].lastTimestamp = uint64(block.timestamp); // Store time alongside it.
            getUserData[msg.sender].emissionMultiple += uint32(burnedMultipleTotal); // Update multiple.
            // Update the total number of gobblers owned by the user. The call to _mint
            // below will increase the count by 1 to account for the new legendary gobbler.
            getUserData[msg.sender].gobblersOwned -= uint32(cost);

            // New start price is the max of LEGENDARY_GOBBLER_INITIAL_START_PRICE and cost * 2.
            legendaryGobblerAuctionData.startPrice = uint128(
                cost <= LEGENDARY_GOBBLER_INITIAL_START_PRICE / 2 ? LEGENDARY_GOBBLER_INITIAL_START_PRICE : cost * 2
            );
            legendaryGobblerAuctionData.numSold = uint128(numSold + 1); // Increment the # of legendaries sold.

            // If gobblerIds has 1,000 elements this should cost around ~270,000 gas.
            emit LegendaryGobblerMinted(msg.sender, gobblerId, gobblerIds[:cost]);

            _mint(msg.sender, gobblerId);
        }
    }

    /// @notice Calculate the legendary gobbler price in terms of gobblers, according to a linear decay function.
    /// @dev The price of a legendary gobbler decays as gobblers are minted. The first legendary auction begins when
    /// 1 LEGENDARY_AUCTION_INTERVAL worth of gobblers are minted, and the price decays linearly while the next interval of
    /// gobblers are minted. Every time an additional interval is minted, a new auction begins until all legendaries have been sold.
    /// @dev Will revert if the auction hasn't started yet or legendaries have sold out entirely.
    /// @return The current price of the legendary gobbler being auctioned, in terms of gobblers.
    function legendaryGobblerPrice() public view returns (uint256) {
        // Retrieve and cache various auction parameters and variables.
        uint256 startPrice = legendaryGobblerAuctionData.startPrice;
        uint256 numSold = legendaryGobblerAuctionData.numSold;

        // If all legendary gobblers have been sold, there are none left to auction.
        if (numSold == LEGENDARY_SUPPLY) revert NoRemainingLegendaryGobblers();

        unchecked {
            // Get and cache the number of standard gobblers sold via VRGDA up until this point.
            uint256 mintedFromGoo = numMintedFromGoo;

            // The number of gobblers minted at the start of the auction is computed by multiplying the # of
            // intervals that must pass before the next auction begins by the number of gobblers in each interval.
            uint256 numMintedAtStart = (numSold + 1) * LEGENDARY_AUCTION_INTERVAL;

            // If not enough gobblers have been minted to start the auction yet, return how many need to be minted.
            if (numMintedAtStart > mintedFromGoo) revert LegendaryAuctionNotStarted(numMintedAtStart - mintedFromGoo);

            // Compute how many gobblers were minted since the auction began.
            uint256 numMintedSinceStart = mintedFromGoo - numMintedAtStart;

            // prettier-ignore
            // If we've minted the full interval or beyond it, the price has decayed to 0.
            if (numMintedSinceStart >= LEGENDARY_AUCTION_INTERVAL) return 0;
            // Otherwise decay the price linearly based on what fraction of the interval has been minted.
            else return FixedPointMathLib.unsafeDivUp(startPrice * (LEGENDARY_AUCTION_INTERVAL - numMintedSinceStart), LEGENDARY_AUCTION_INTERVAL);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            RANDOMNESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Request a new random seed for revealing gobblers.
    function requestRandomSeed() external returns (bytes32) {
        uint256 nextRevealTimestamp = gobblerRevealsData.nextRevealTimestamp;

        // A new random seed cannot be requested before the next reveal timestamp.
        if (block.timestamp < nextRevealTimestamp) revert RequestTooEarly();

        // A random seed can only be requested when all gobblers from the previous seed have been revealed.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (gobblerRevealsData.toBeRevealed != 0) revert RevealsPending();

        unchecked {
            // Prevent revealing while we wait for the seed.
            gobblerRevealsData.waitingForSeed = true;

            // Compute the number of gobblers to be revealed with the seed.
            uint256 toBeRevealed = currentNonLegendaryId - gobblerRevealsData.lastRevealedId;

            // Ensure that there are more than 0 gobblers to be revealed,
            // otherwise the contract could waste LINK revealing nothing.
            if (toBeRevealed == 0) revert ZeroToBeRevealed();

            // Lock in the number of gobblers to be revealed from seed.
            gobblerRevealsData.toBeRevealed = uint56(toBeRevealed);

            // We enable reveals for a set of gobblers every 24 hours.
            // Timestamp overflow is impossible on human timescales.
            gobblerRevealsData.nextRevealTimestamp = uint64(nextRevealTimestamp + 1 days);

            emit RandomnessRequested(msg.sender, toBeRevealed);
        }

        // Call out to the randomness provider.
        return randProvider.requestRandomBytes();
    }

    /// @notice Callback from rand provider. Sets randomSeed. Can only be called by the rand provider.
    /// @param randomness The 256 bits of verifiable randomness provided by the rand provider.
    function acceptRandomSeed(bytes32, uint256 randomness) external {
        // The caller must be the randomness provider, revert in the case it's not.
        if (msg.sender != address(randProvider)) revert NotRandProvider();

        // The unchecked cast to uint64 is equivalent to moduloing the randomness by 2**64.
        gobblerRevealsData.randomSeed = uint64(randomness); // 64 bits of randomness is plenty.

        gobblerRevealsData.waitingForSeed = false; // We have the seed now, open up reveals.

        emit RandomnessFulfilled(randomness);
    }

    /// @notice Upgrade the rand provider contract. Useful if current VRF is sunset.
    /// @param newRandProvider The new randomness provider contract address.
    function upgradeRandProvider(RandProvider newRandProvider) external onlyOwner {
        // Reset reveal state when we upgrade while the seed is pending. This gives us a
        // safeguard against malfunctions since we won't be stuck waiting for a seed forever.
        if (gobblerRevealsData.waitingForSeed) {
            gobblerRevealsData.waitingForSeed = false;
            gobblerRevealsData.toBeRevealed = 0;
            gobblerRevealsData.nextRevealTimestamp -= 1 days;
        }

        randProvider = newRandProvider; // Update the randomness provider.

        emit RandProviderUpgraded(msg.sender, newRandProvider);
    }

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Knuth shuffle to progressively reveal
    /// new gobblers using entropy from a random seed.
    /// @param numGobblers The number of gobblers to reveal.
    function revealGobblers(uint256 numGobblers) external {
        uint256 randomSeed = gobblerRevealsData.randomSeed;

        uint256 lastRevealedId = gobblerRevealsData.lastRevealedId;

        uint256 totalRemainingToBeRevealed = gobblerRevealsData.toBeRevealed;

        // Can't reveal if we're still waiting for a new seed.
        if (gobblerRevealsData.waitingForSeed) revert SeedPending();

        // Can't reveal more gobblers than are currently remaining to be revealed with the seed.
        if (numGobblers > totalRemainingToBeRevealed) revert NotEnoughRemainingToBeRevealed(totalRemainingToBeRevealed);

        // Implements a Knuth shuffle. If something in
        // here can overflow, we've got bigger problems.
        unchecked {
            for (uint256 i = 0; i < numGobblers; ++i) {
                /*//////////////////////////////////////////////////////////////
                                      DETERMINE RANDOM SWAP
                //////////////////////////////////////////////////////////////*/

                // Number of ids that have not been revealed. Subtract 1
                // because we don't want to include any legendaries in the swap.
                uint256 remainingIds = FIRST_LEGENDARY_GOBBLER_ID - lastRevealedId - 1;

                // Randomly pick distance for swap.
                uint256 distance = randomSeed % remainingIds;

                // Current id is consecutive to last reveal.
                uint256 currentId = ++lastRevealedId;

                // Select swap id, adding distance to next reveal id.
                uint256 swapId = currentId + distance;

                /*//////////////////////////////////////////////////////////////
                                       GET INDICES FOR IDS
                //////////////////////////////////////////////////////////////*/

                // Get the index of the swap id.
                uint64 swapIndex = getGobblerData[swapId].idx == 0
                    ? uint64(swapId) // Hasn't been shuffled before.
                    : getGobblerData[swapId].idx; // Shuffled before.

                // Get the owner of the current id.
                address currentIdOwner = getGobblerData[currentId].owner;

                // Get the index of the current id.
                uint64 currentIndex = getGobblerData[currentId].idx == 0
                    ? uint64(currentId) // Hasn't been shuffled before.
                    : getGobblerData[currentId].idx; // Shuffled before.

                /*//////////////////////////////////////////////////////////////
                                  SWAP INDICES AND SET MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Determine the current id's new emission multiple.
                uint256 newCurrentIdMultiple = 9; // For beyond 7963.

                // The branchless expression below is equivalent to:
                //      if (swapIndex <= 3054) newCurrentIdMultiple = 6;
                // else if (swapIndex <= 5672) newCurrentIdMultiple = 7;
                // else if (swapIndex <= 7963) newCurrentIdMultiple = 8;
                assembly {
                    // prettier-ignore
                    newCurrentIdMultiple := sub(sub(sub(
                        newCurrentIdMultiple,
                        lt(swapIndex, 7964)),
                        lt(swapIndex, 5673)),
                        lt(swapIndex, 3055)
                    )
                }

                // Swap the index and multiple of the current id.
                getGobblerData[currentId].idx = swapIndex;
                getGobblerData[currentId].emissionMultiple = uint32(newCurrentIdMultiple);

                // Swap the index of the swap id.
                getGobblerData[swapId].idx = currentIndex;

                /*//////////////////////////////////////////////////////////////
                                   UPDATE CURRENT ID MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Update the user data for the owner of the current id.
                getUserData[currentIdOwner].lastBalance = uint128(gooBalance(currentIdOwner));
                getUserData[currentIdOwner].lastTimestamp = uint64(block.timestamp);
                getUserData[currentIdOwner].emissionMultiple += uint32(newCurrentIdMultiple);

                // Update the random seed to choose a new distance for the next iteration.
                // It is critical that we cast to uint64 here, as otherwise the random seed
                // set after calling revealGobblers(1) thrice would differ from the seed set
                // after calling revealGobblers(3) a single time. This would enable an attacker
                // to choose from a number of different seeds and use whichever is most favorable.
                // Equivalent to randomSeed = uint64(uint256(keccak256(abi.encodePacked(randomSeed))))
                assembly {
                    mstore(0, randomSeed) // Store the random seed in scratch space.

                    // Moduloing by 2 ** 64 is equivalent to a uint64 cast.
                    randomSeed := mod(keccak256(0, 32), exp(2, 64))
                }
            }

            // Update all relevant reveal state.
            gobblerRevealsData.randomSeed = uint64(randomSeed);
            gobblerRevealsData.lastRevealedId = uint64(lastRevealedId);
            gobblerRevealsData.toBeRevealed = uint56(totalRemainingToBeRevealed - numGobblers);

            emit GobblersRevealed(msg.sender, numGobblers, lastRevealedId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a token's URI if it has been minted.
    /// @param gobblerId The id of the token to get the URI for.
    function tokenURI(uint256 gobblerId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealed are revealed normal gobblers.
        if (gobblerId <= gobblerRevealsData.lastRevealedId) {
            if (gobblerId == 0) revert("NOT_MINTED"); // 0 is not a valid id for Art Gobblers.

            return string.concat(BASE_URI, uint256(getGobblerData[gobblerId].idx).toString());
        }

        // Between lastRevealed + 1 and currentNonLegendaryId are minted but not revealed.
        if (gobblerId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and FIRST_LEGENDARY_GOBBLER_ID are unminted.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID) revert("NOT_MINTED");

        // Between FIRST_LEGENDARY_GOBBLER_ID and FIRST_LEGENDARY_GOBBLER_ID + numSold are minted legendaries.
        if (gobblerId < FIRST_LEGENDARY_GOBBLER_ID + legendaryGobblerAuctionData.numSold)
            return string.concat(BASE_URI, gobblerId.toString());

        revert("NOT_MINTED"); // Unminted legendaries and invalid token ids.
    }

    /*//////////////////////////////////////////////////////////////
                            GOBBLE ART LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Feed a gobbler a work of art.
    /// @param gobblerId The gobbler to feed the work of art.
    /// @param nft The ERC721 or ERC1155 contract of the work of art.
    /// @param id The id of the work of art.
    /// @param isERC1155 Whether the work of art is an ERC1155 token.
    function gobble(
        uint256 gobblerId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        // Get the owner of the gobbler to feed.
        address owner = getGobblerData[gobblerId].owner;

        // The caller must own the gobbler they're feeding.
        if (owner != msg.sender) revert OwnerMismatch(owner);

        // Gobblers have taken a vow not to eat other gobblers.
        if (nft == address(this)) revert Cannibalism();

        unchecked {
            // Increment the # of copies gobbled by the gobbler. Unchecked is
            // safe, as an NFT can't have more than type(uint256).max copies.
            ++getCopiesOfArtGobbledByGobbler[gobblerId][nft][id];
        }

        emit ArtGobbled(msg.sender, gobblerId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "")
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }

    /*//////////////////////////////////////////////////////////////
                                GOO LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance using LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].lastBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /// @notice Add goo to your emission balance,
    /// burning the corresponding ERC20 balance.
    /// @param gooAmount The amount of goo to add.
    function addGoo(uint256 gooAmount) external {
        // Burn goo being added to gobbler.
        goo.burnForGobblers(msg.sender, gooAmount);

        // Increase msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, gooAmount, GooBalanceUpdateType.INCREASE);
    }

    /// @notice Remove goo from your emission balance, and
    /// add the corresponding amount to your ERC20 balance.
    /// @param gooAmount The amount of goo to remove.
    function removeGoo(uint256 gooAmount) external {
        // Decrease msg.sender's virtual goo balance.
        updateUserGooBalance(msg.sender, gooAmount, GooBalanceUpdateType.DECREASE);

        // Mint the corresponding amount of ERC20 goo.
        goo.mintForGobblers(msg.sender, gooAmount);
    }

    /// @notice Burn an amount of a user's virtual goo balance. Only callable
    /// by the Pages contract to enable purchasing pages with virtual balance.
    /// @param user The user whose virtual goo balance we should burn from.
    /// @param gooAmount The amount of goo to burn from the user's virtual balance.
    function burnGooForPages(address user, uint256 gooAmount) external {
        // The caller must be the Pages contract, revert otherwise.
        if (msg.sender != address(pages)) revert UnauthorizedCaller(msg.sender);

        // Burn the requested amount of goo from the user's virtual goo balance.
        // Will revert if the user doesn't have enough goo in their virtual balance.
        updateUserGooBalance(user, gooAmount, GooBalanceUpdateType.DECREASE);
    }

    /// @dev An enum for representing whether to
    /// increase or decrease a user's goo balance.
    enum GooBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to update the user's virtual balance by.
    /// @param updateType Whether to increase or decrease the user's balance by gooAmount.
    function updateUserGooBalance(
        address user,
        uint256 gooAmount,
        GooBalanceUpdateType updateType
    ) internal {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = updateType == GooBalanceUpdateType.INCREASE
            ? gooBalance(user) + gooAmount
            : gooBalance(user) - gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].lastBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint64(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
    }

    /*//////////////////////////////////////////////////////////////
                     RESERVED GOBBLERS MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of gobblers to the reserves.
    /// @param numGobblersEach The number of gobblers to mint to each reserve.
    /// @dev Gobblers minted to reserves cannot comprise more than 20% of the sum of
    /// the supply of goo minted gobblers and the supply of gobblers minted to reserves.
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId) {
        unchecked {
            // Optimistically increment numMintedForReserves, may be reverted below.
            // Overflow in this calculation is possible but numGobblersEach would have to
            // be so large that it would cause the loop in _batchMint to run out of gas quickly.
            uint256 newNumMintedForReserves = numMintedForReserves += (numGobblersEach * 2);

            // Ensure that after this mint gobblers minted to reserves won't comprise more than 20% of
            // the sum of the supply of goo minted gobblers and the supply of gobblers minted to reserves.
            if (newNumMintedForReserves > (numMintedFromGoo + newNumMintedForReserves) / 5) revert ReserveImbalance();
        }

        // Mint numGobblersEach gobblers to both the team and community reserve.
        lastMintedGobblerId = _batchMint(team, numGobblersEach, currentNonLegendaryId);
        lastMintedGobblerId = _batchMint(community, numGobblersEach, lastMintedGobblerId);

        currentNonLegendaryId = uint128(lastMintedGobblerId); // Set currentNonLegendaryId.

        emit ReservedGobblersMinted(msg.sender, lastMintedGobblerId, numGobblersEach);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get emissionMultiple for a gobbler.
    /// @param gobblerId The gobbler to get emissionMultiple for.
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256) {
        return getGobblerData[gobblerId].emissionMultiple;
    }

    /// @notice Convenience function to get emissionMultiple for a user.
    /// @param user The user to get emissionMultiple for.
    function getUserEmissionMultiple(address user) external view returns (uint256) {
        return getUserData[user].emissionMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == getGobblerData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        delete getApproved[id];

        getGobblerData[id].owner = to;

        unchecked {
            uint32 emissionMultiple = getGobblerData[id].emissionMultiple; // Caching saves gas.

            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) emission multiple.
            getUserData[from].lastBalance = uint128(gooBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);
            getUserData[from].emissionMultiple -= emissionMultiple;
            getUserData[from].gobblersOwned -= 1;

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) emission multiple.
            getUserData[to].lastBalance = uint128(gooBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
            getUserData[to].emissionMultiple += emissionMultiple;
            getUserData[to].gobblersOwned += 1;
        }

        emit Transfer(from, to, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/*                                                                %#/*********(&,
                                                              .#*********************#.
                                                            #****./*********************%
                                                          %*******************************%
                                                        &**********************************,((
                                                       @(*,***********************************#&
                                                    (*********************#***********************(
                                                  ,%@/**************#%***%**&***%*******************,
                                                  /********************#****#*#******,**************%
                                                 ,************,#(*****************(#/&(*,*,*********#
                                                 **************(%%(&************#@%(///************(
                                                ./**************,*./##****************************#*%
                                               #**&**************************************************&@@@@@&@&%#((./.
                                              (*******************@&%&@@@.   /    %  &********(@/,****,,,*,,,****,,*,**********,*,
                                             &******************#  /    *     /   /    .. %/****(******************,**&***********./
                                  /%(*******************&***./#    #.#%%    .,    .,   ##&&@****#***********************************.
                         *#(*,**************************(***(///.*     *     #     #   .  %*****(/*************************************&
                 *(***********************************.//****&    #     #    (#&((%@*,*&(******(%************./@#*   *%&%(/&*************(
               #,**************************************,&******&..*#&(*****,,,,/********************************             (/******,**,**,
              %*****************************************.//**************#**************************************               .(***********#
             (*************************./************************************************************************              @**************
             ,**********&@@@&&%#        &,**********************************************************************@             ./*,%*,********./
            ***********                .************@(*************(&#///////////////.//#&%/*****************&*,,                &************%
           (**********.                 .%********************(&./////////////////////////////(%******************                *(**&,&##*
          #**********(,                &,*./***************%(///////////////////////////////////*&****************
        (************%                %,*****************&///////////////////////////////////////*(***************.
      .(***************(             #******************&//////////////////////////////////////////****************
     .&*************%*./            .*******************%/////////////////////////////////////////****************##
      .*************%*%             (********************#(///////////////////////////////////(#*****************&**,***,.
           #***./,***%              #**********************,%%*./////////////////////////*(@*******************(/****./********,((
           @@,                    &**@*****************************./(%@&%%((((((%&&%(*********************************&,**********.
                         .   .#,,*****./&/*****************************************************************************************
                          %,******************************************************************************************************#
                       %*******@*****************************************************./#%%,...((,           .,********************(
                     ,*******************************@&(**./%&%*        .,//(//////////,                           ,************./
                      /**************************&*                      ////*(/////////                            ***(*********%
                       (*********************(#                         ..///////////(//(                          .***********./
                         #******************%                       *..,,,(//////////(//(*.//,                     %***************&
                           %*****************                   ////////&&&&&&&&%#(//(&@&#(#@@                    &*********************#
                             #****************.                 ,//(//////(@@%%%%%///////****&                   &************************(
                           .**&***(************./               [email protected],(///(/(.//(***((*(//*****@/&                ,*************************./
                            &********************#             .(#(@#//(****(//(*****(/(&(..&(                  ./*********************(#.
                        #/***********************./          /,,./*((#%@(%&%(((((((#%&&&/(#(#@(
                      #*,***********************,*&                 .%@@@&#,  ///(/*
                     (*************************%                             ..(/,./(,.,*
                      /#/*./(%&(.*/

/// @title Goo Token (GOO)
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Goo is the in-game token for ArtGobblers. It's a standard ERC20
/// token that can be burned and minted by the gobblers and pages contract.
contract Goo is ERC20("Goo", "GOO", 18) {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Art Gobblers contract.
    address public immutable artGobblers;

    /// @notice The address of the Pages contract.
    address public immutable pages;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the addresses of relevant contracts.
    /// @param _artGobblers Address of the ArtGobblers contract.
    /// @param _pages Address of the Pages contract.
    constructor(address _artGobblers, address _pages) {
        artGobblers = _artGobblers;
        pages = _pages;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Mint any amount of goo to a user. Can only be called by ArtGobblers.
    /// @param to The address of the user to mint goo to.
    /// @param amount The amount of goo to mint.
    function mintForGobblers(address to, uint256 amount) external only(artGobblers) {
        _mint(to, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by ArtGobblers.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnForGobblers(address from, uint256 amount) external only(artGobblers) {
        _burn(from, amount);
    }

    /// @notice Burn any amount of goo from a user. Can only be called by Pages.
    /// @param from The address of the user to burn goo from.
    /// @param amount The amount of goo to burn.
    function burnForPages(address from, uint256 amount) external only(pages) {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LibString} from "solmate/utils/LibString.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LogisticToLinearVRGDA} from "VRGDAs/LogisticToLinearVRGDA.sol";

import {PagesERC721} from "./utils/token/PagesERC721.sol";

import {Goo} from "./Goo.sol";
import {ArtGobblers} from "./ArtGobblers.sol";

/*                                                                                   &@./(
                                                                                    &//*&
                                                                                   @/*.&
                                                                                 (#/./%
                                                             .,(#%%&@@&%#(/,    *#./#,                   .*(%@@@@&%#((//////(#&@%.
                                                      #&@&/*./*************.///&@%&@@@@@@@@&%#(///**********./********************#&
                                                  &@(/*****************************************************************************#/
                                               (&**********************************************************************************@
                                              @**********************************************************************************(&
                                             &/*******************************************************************************%@.
           ,(                                *&/***********************************************************************./#@@%(((#@%
            .//                                (@/***./*****************************************************.///#&@@@&##(((#(##((##%&
             /*.//                                 *@@&#(/////(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&%%%%%####(#(((((((##(((##((#(###((((#@&
              (****./                               @###(###(((((###(##((#(((((#(#####((((#(((((((#((((((((((((((((((((#(##(####((((#(#@
              /******./                            &#((#########(############((#(######(########(####(##(###%&&&%########%&&%###((((####@
              ,********./                         /&((((#(#((##(((#(((#((########(###((((((((((((((((#((%&#((#((#((((((((((#((((((((((((#@
              .**********(                        @#(#(#####(###(#&&&#(((((((((#(((%@%##########(######&#((#&#(((##((((%&@%#((##(#(((#((#%&
               /**********(                      /%(#(((((#((#&%(((#(###(#########(((###(((#####(###((#(%@%###(###((((##(((##&%#(##(((##(#@,
               (**********./                     @#(#(((((###((#(#((#(((((###(((#(#%@@###((#####(###((#&%&&/.              .*#&&@#((((((((%@
               ./**********(                    ,%((((((((##((((#&@#(##((((((##%%&&&&%%#&##((###(##((%*                          [email protected]#(##((##@.
                ./********./                    %#((#(((((#####@##(##%@&(.                %#((#((###%*            *(,.             %#((#(((@,
                  /********(                    @#((#((((####@#%@#                         .&((((##(&           &@@@@@@%            &#((#&#&,
                    /******(                   ,&(#(#((((###@&                              .&##(###&            /@@@@@@            (%((((#@%
                      ./*#@@@@*                (%#(((((#((#&           #@@@@@&.              (%#(#((&.            /#.               ##(#(#(##@&
                       @%(/((((&               &####(((((#@            [email protected]@@@@@@               &((##(#@@(.                      .#&%#&(#####((##@.
                      /#(((((((##         (#*  @##(#(((((#@             ,@@@/*               @&((####(&&#(##%%&&&%%##%&&&&&%##(((#%%(###((####((&&
                       #((((%@@@@@.    @#(((#@*&##(((((((#@                              .%&#@#((####(((#((#(((((((((((((((((((##%((#(###((#####(#@
                       #@/,,,@#((#%(  @((&%,,,&&%((((((#(#&,                        .%@%#((#@%(((###((((#(((##%&&&&&&&&&&&%#((((####(###(###(###((#@%
                   #@##&(,,,(&(##(#@ &###@**#@@@@(((((((##(@@@#,            ,(@@&##(((((((((#((((#####((#%@@@@@@@@@@@@@@@@@&&%%################%%(##@&
                %&##((((#&@@%(((((%# &##(####(#&@&(((((((#(##@#((((((((##((###(#(#(((#%&##(#####(####(##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%##(((#((%@
             *&#((#######((((###(%&@ (#(####(((#&@%(((((####(##%&##(#((((###(###%@@%###(##%%%###(#(####@@@@&%###((##((((((((##((((((((##((((((#((##(#@
           (&((((((((((((((((##@&/((@@&####(((((((#&&%#(#((((((((#(((((#((###(#((#&@&&@@@@@@@@%((((((#((((#((((((((((((((((((((((((((((((((((((((((((#
         [email protected]#(##((((((((((#((&@#%@@&%%&@&##(((###(#####(#@%##(###((#######(((#(#%@#(((#((#(######(###############(###############(###############(##(##
        (%(#((#((((((((((#&@%#(%%,,,,&#(#@######(####(((((%%(#(#(###(#(((#%@@@@@&##(####(((#(#(#(#######(#######(#######(#######(#######(#######(##((#
       (%((####((###(#&@########@*,,,@#(#%@(((#((#######(((#&(##(###(%@@@@@%##((#@&%####&@@%(###(###############(###############(###############(###(#
       @((##(##(((#@%#(#((##(#(#(#&@&#(##@&&@@@&##(#(###(#((&##%&@@%##(#(#(((####((((&%((###((#&####(###(###(###(###(###(###(###(###(###(###(###(####(
       @((#(((##@%(((((((######((###(#&@%#(#(#(#(##########(%%((((#((((#(((((((((((((#&&#(###&&(((##############(###############(###############(#####
       .%(#(#%@#((###(#((########&@@((((&#(#####((######(##(%&#((#######(#######(#####(#####((##(#######(#######(#######(#######(#######(#######(#####
         &##@#(#((##((#####(#&&#(((#&(((@#######(##########(&%%#(#((##(#########(############((((###############(###############(###############(#####
          *%(((#(#(#(#(#(#%@#(((((((((##(((((((#(#(#(#(#(#(#@###(((#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#
         ,&(##(#(#####((%@#(###((((((((####((###(########((%@&##(###############(###############(###############(###############(###############(#####
         &#((((#(##(####&%(##(((((%@%((#(#######(######(##%@&#((((######(#######(#######(#######(#######(#######(#######(#######(#######(#######(#####
         %###((#(##########((###((##((##########(####(#((&&###(((###############(###############(###############(###############(###############(#####
          &#(#(#(###(###(##((###(###((##(###(###(###((#&&#######(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(###(#
           %%(#(###(#(#(########(#####(#########(###((#&%#(#####(###############(###############(###############(###############(#############(((#####
              (&%%#%#%#((#(#####(#######(#######(######((#&%(###(#######(#######(#######(#######(#######(#######(#######(#######((##(##((#(#(###(((###
                       ##(#(####(###############(######(((((####(###############(###############(###############(#############(##(#((##%%&@@@@&&&%%%%%
                         &((((((((((((((((((((((((((((((((((((##((((((((((((((((((((((((((((((((((((((((((((((((((((((((##(((##&@@&&%%%%%%%%%%%%%%%%%%
                          &#(((#(###############(#############%&((((############(###############(###############(#######%&@&%%%%%%%%%%%%%%%%%%%%%%%%%%
                           @####(#######(#######(#######(##(%&(((#(#####(#######(#######(#######(#######(#######((##%@&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            @#(((###############(#######((#@#(##(###############(###############(##############(%@&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                             &(#(###(###(###(###(###(##((#&###(((###(###(###(###(###(###(###(###(###(###(#####@&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                             /%((###############(#####((#&######(###############(###############(#(########&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                              &#(#######(#######(######(%%##((##(#######(#######(#######(#######(####(((#@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                               @################(######(%%##((##((##############(###############(##(###@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                &##((#(#(#(#(#(#(#(#(#(#(@##(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(#(##@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                (%(((###########(#######(#&&##(#(###############(################(#@&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                 ##(####(#######(#######(#(#%&#((#######(#######(#######(#######(&@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                  /%(((###(#####(########(###(#&%###############(############((#@&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/// @title Pages NFT
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Pages is an ERC721 that can hold custom art.
contract Pages is PagesERC721, LogisticToLinearVRGDA {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the goo ERC20 token contract.
    Goo public immutable goo;

    /// @notice The address which receives pages reserved for the community.
    address public immutable community;

    /*//////////////////////////////////////////////////////////////
                                  URIS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base URI for minted pages.
    string public BASE_URI;

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Id of the most recently minted page.
    /// @dev Will be 0 if no pages have been minted yet.
    uint128 public currentId;

    /*//////////////////////////////////////////////////////////////
                          COMMUNITY PAGES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of pages minted to the community reserve.
    uint128 public numMintedForCommunity;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The day the switch from a logistic to translated linear VRGDA is targeted to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_DAY_WAD = 233e18;

    /// @notice The minimum amount of pages that must be sold for the VRGDA issuance
    /// schedule to switch from logistic to the "post switch" translated linear formula.
    /// @dev Computed off-chain by plugging SWITCH_DAY_WAD into the uninverted pacing formula.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SOLD_BY_SWITCH_WAD = 8336.760939794622713006e18;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PagePurchased(address indexed user, uint256 indexed pageId, uint256 price);

    event CommunityPagesMinted(address indexed user, uint256 lastMintedPageId, uint256 numPages);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ReserveImbalance();

    error PriceExceededMax(uint256 currentPrice);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint start, relevant addresses, and base URI.
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _goo Address of the Goo contract.
    /// @param _community Address of the community reserve.
    /// @param _artGobblers Address of the ArtGobblers contract.
    /// @param _baseUri Base URI for token metadata.
    constructor(
        // Mint config:
        uint256 _mintStart,
        // Addresses:
        Goo _goo,
        address _community,
        ArtGobblers _artGobblers,
        // URIs:
        string memory _baseUri
    )
        PagesERC721(_artGobblers, "Pages", "PAGE")
        LogisticToLinearVRGDA(
            4.2069e18, // Target price.
            0.31e18, // Price decay percent.
            9000e18, // Logistic asymptote.
            0.014e18, // Logistic time scale.
            SOLD_BY_SWITCH_WAD, // Sold by switch.
            SWITCH_DAY_WAD, // Target switch day.
            9e18 // Pages to target per day.
        )
    {
        mintStart = _mintStart;

        goo = _goo;

        community = _community;

        BASE_URI = _baseUri;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a page with goo, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the page.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual goo balance, or from their ERC20 goo balance.
    /// @return pageId The id of the page that was minted.
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 pageId) {
        // Will revert if prior to mint start.
        uint256 currentPrice = pagePrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's goo balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance
            ? artGobblers.burnGooForPages(msg.sender, currentPrice)
            : goo.burnForPages(msg.sender, currentPrice);

        unchecked {
            emit PagePurchased(msg.sender, pageId = ++currentId, currentPrice);

            _mint(msg.sender, pageId);
        }
    }

    /// @notice Calculate the mint cost of a page.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function pagePrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        unchecked {
            // The number of pages minted for the community reserve
            // should never exceed 10% of the total supply of pages.
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), currentId - numMintedForCommunity);
        }
    }

    /*//////////////////////////////////////////////////////////////
                      COMMUNITY PAGES MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of pages to the community reserve.
    /// @param numPages The number of pages to mint to the reserve.
    /// @dev Pages minted to the reserve cannot comprise more than 10% of the sum of the
    /// supply of goo minted pages and the supply of pages minted to the community reserve.
    function mintCommunityPages(uint256 numPages) external returns (uint256 lastMintedPageId) {
        unchecked {
            // Optimistically increment numMintedForCommunity, may be reverted below.
            // Overflow in this calculation is possible but numPages would have to be so
            // large that it would cause the loop in _batchMint to run out of gas quickly.
            uint256 newNumMintedForCommunity = numMintedForCommunity += uint128(numPages);

            // Ensure that after this mint pages minted to the community reserve won't comprise more than
            // 10% of the new total page supply. currentId is equivalent to the current total supply of pages.
            if (newNumMintedForCommunity > ((lastMintedPageId = currentId) + numPages) / 10) revert ReserveImbalance();

            // Mint the pages to the community reserve and update lastMintedPageId once minting is complete.
            lastMintedPageId = _batchMint(community, numPages, lastMintedPageId);

            currentId = uint128(lastMintedPageId); // Update currentId with the last minted page id.

            emit CommunityPagesMinted(msg.sender, lastMintedPageId, numPages);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a page's URI if it has been minted.
    /// @param pageId The id of the page to get the URI for.
    function tokenURI(uint256 pageId) public view virtual override returns (string memory) {
        if (pageId == 0 || pageId > currentId) revert("NOT_MINTED");

        return string.concat(BASE_URI, pageId.toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Randomness Provider Interface.
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Generic asynchronous randomness provider interface.
interface RandProvider {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RandomBytesRequested(bytes32 requestId);
    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Request random bytes from the randomness provider.
    function requestRandomBytes() external returns (bytes32 requestId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

/// @notice ERC721 implementation optimized for ArtGobblers by packing balanceOf/ownerOf with user/attribute data.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract GobblersERC721 {
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

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                         GOBBLERS/ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding gobbler data.
    struct GobblerData {
        // The current owner of the gobbler.
        address owner;
        // Index of token after shuffle.
        uint64 idx;
        // Multiple on goo issuance.
        uint32 emissionMultiple;
    }

    /// @notice Maps gobbler ids to their data.
    mapping(uint256 => GobblerData) public getGobblerData;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of gobblers currently owned by the user.
        uint32 gobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 lastBalance;
        // Timestamp of the last goo balance checkpoint.
        uint64 lastTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = getGobblerData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return getUserData[owner].gobblersOwned;
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

    function approve(address spender, uint256 id) external {
        address owner = getGobblerData[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
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
    ) external {
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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        // Does not check if the token was already minted or the recipient is address(0)
        // because ArtGobblers.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            ++getUserData[to].gobblersOwned;
        }

        getGobblerData[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId
    ) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because ArtGobblers.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            getUserData[to].gobblersOwned += uint32(amount);

            for (uint256 i = 0; i < amount; ++i) {
                getGobblerData[++lastMintedId].owner = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ArtGobblers} from "../../ArtGobblers.sol";

/// @notice ERC721 implementation optimized for Pages by pre-approving them to the ArtGobblers contract.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract PagesERC721 {
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

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    ArtGobblers public immutable artGobblers;

    constructor(
        ArtGobblers _artGobblers,
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        artGobblers = _artGobblers;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) internal _isApprovedForAll;

    function isApprovedForAll(address owner, address operator) public view returns (bool isApproved) {
        if (operator == address(artGobblers)) return true; // Skip approvals for the ArtGobblers contract.

        return _isApprovedForAll[owner][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll(from, msg.sender) || msg.sender == getApproved[id],
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
    ) external {
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
    ) external {
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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        // Does not check the token has not been already minted
        // or is being minted to address(0) because ids in Pages.sol
        // are set using a monotonically increasing counter and only
        // minted to safe addresses or msg.sender who cannot be zero.

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId
    ) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because Pages.sol manages its ids in a way that it ensures it won't double
        // mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            _balanceOf[to] += amount;

            for (uint256 i = 0; i < amount; ++i) {
                _ownerOf[++lastMintedId] = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}
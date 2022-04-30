// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./tokens/ERC721.sol";
import "./tokens/ERC20.sol";
import "./utils/owner.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RapPearsNft is ERC721, Owner {
    using Strings for *;
    ///=============================================================================================
    /// Data Struct
    ///=============================================================================================

    struct Rewards {
        uint256 weight;
        uint256 tracker; //sum of delta(deposit) * yeildPerDeposit || SCALED
    }

    struct MetaData {
        string name;
        address vaultAddress;
        uint256 withdrawable;
        uint256 id;
        uint256 vaultType;
    }

    ///=============================================================================================
    /// Accounting State
    ///=============================================================================================

    // tokenID => Deposits
    mapping(uint256 => Rewards) public deposits;

    //sum of yeild/totalWeight scaled by SCALAR
    uint256 public yeildPerDeposit;

    uint256 public totalWeight;

    uint256 constant SCALAR = 1e10;

    ///=============================================================================================
    /// Rappears
    ///=============================================================================================

    // tokenId => lockUp timestamp
    mapping(uint256 => uint256) locked;
    uint256 internal lockTimeSeconds;

    mapping(uint256 => mapping(address => bool)) public privateMintClaimed;

    mapping(uint256 => mapping(uint256 => uint256)) public qtyPricing;
    uint256 public defaultPricePerUnit = 1e17;
    uint256 public pricingVersionCount = 1;

    uint256 public maxWhitelistMintPerTx;

    bool internal publicMint;
    uint256 internal supplyCap;

    mapping(address => uint256[]) public tokensByAddress;

    // returns the current index in the tokensByAddress array
    mapping(uint256 => uint256) internal indexById;

    ///=============================================================================================
    /// Misc
    ///=============================================================================================

    ERC20 public weth;

    uint256 internal devFeeBP;

    uint256 public devBalance;

    uint256 public currentId;

    ///=============================================================================================
    /// External Logic
    ///=============================================================================================

    constructor(
        address _weth,
        uint256 _devFeeBP,
        uint256 _lockTime,
        uint256 _initalSupplyCap,
        uint256 _initialMintAmount,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        weth = ERC20(_weth);
        devFeeBP = _devFeeBP;
        lockTimeSeconds = _lockTime;
        supplyCap = _initalSupplyCap;
        setMaxWhiteList(5);
        ipfsLink = "ipfs://QmWYt6XezHy7PBwCYEHpWZYfSemjGwWMpHSxRmXVfSFEvQ/";
        maxWhitelistMintPerTx = 5;

        for (uint256 i; i < _initialMintAmount; ) {
            _mintNewNFT();
            unchecked {
                ++i;
            }
        }
    }

    function adminMint(uint256 amount)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        _takeFees();
        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();
            // unlikely to overflow
            unchecked {
                ++i;
            }
        }
        return ret;
    }

    function mintNewNft(uint256 amount)
        external
        payable
        returns (uint256[] memory)
    {
        require(price(amount) <= msg.value, "underpaid");
        require(publicMint, "not live");

        _takeFees();

        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();

            // unlikely to overflow
            unchecked {
                ++i;
            }
        }

        return ret;
    }

    function lockUp(uint256 id) external {
        require(msg.sender == ownerOf(id), "Not Owner");

        locked[id] = block.timestamp;
        deposits[id].weight = 100; // 100 = 1 weight
        deposits[id].tracker += 100 * yeildPerDeposit;
        totalWeight += 100;
    }

    event A(uint256);

    function withdrawFromId(uint256 id, uint256 amount) public {
        require(
            block.timestamp - locked[id] >= lockTimeSeconds && locked[id] != 0,
            "here"
        );

        locked[id] = 0;

        _withdrawFromId(amount, id);
    }

    function bundleWithdraw() external {
        uint256 length = tokensByAddress[msg.sender].length;
        for (uint256 i; i < length; ) {
            uint256 id = tokensByAddress[msg.sender][i];
            if (
                block.timestamp - locked[id] >= lockTimeSeconds &&
                locked[id] != 0
            ) {
                withdrawFromId(id, withdrawableById(id));
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdrawableById(uint256 id)
        public
        view
        returns (uint256 claimId)
    {
        return yieldPerId(id);
    }

    function claimDevFeeBPs() external onlyOwner {
        weth.transfer(owner, devBalance);
    }

    ///=============================================================================================
    /// Internal Logic
    ///=============================================================================================

    function _mintNewNFT() internal returns (uint256) {
        uint256 id = ++currentId;
        require(currentId <= supplyCap);

        _mint(msg.sender, id);
        _addId(msg.sender, id);

        return id;
    }

    function _withdrawFromId(uint256 amount, uint256 id) internal {
        require(msg.sender == ownerOf(id) && amount <= withdrawableById(id));

        deposits[id].weight = 0; // user ceases to earn yield
        deposits[id].tracker = 0;
        totalWeight -= 100;

        weth.transfer(msg.sender, amount);
    }

    function _takeFees() internal {
        // grieifing is a non issue here
        (bool success, ) = payable(address(weth)).call{value: msg.value}("");
        require(success);

        uint256 toDev = (msg.value * devFeeBP) / 10000;
        devBalance += toDev;

        if (totalWeight > 0) {
            distributeYeild(msg.value - toDev);
        } else {
            devBalance += (msg.value - toDev);
        }
    }

    // add to list of ID by address
    function _addId(address who, uint256 id) internal {
        tokensByAddress[who].push(id);

        indexById[id] = tokensByAddress[who].length - 1;
    }

    // remove from list of id by address
    function _removeId(address who, uint256 id) internal {
        uint256 index = indexById[id]; // get index of value to remove

        uint256 lastVal = tokensByAddress[who][tokensByAddress[who].length - 1]; // get last val from array

        tokensByAddress[who][index] = lastVal; // set last value to remove index of value to remove

        tokensByAddress[who].pop(); //pop off the now duplicate value
    }

    ///=============================================================================================
    /// Yield
    ///=============================================================================================

    function distributeYeild(uint256 amount) public virtual {
        yeildPerDeposit += ((amount * SCALAR) / totalWeight);
    }

    function yieldPerId(uint256 id) public view returns (uint256) {
        uint256 pre = (deposits[id].weight * yeildPerDeposit) / SCALAR;
        return pre - (deposits[id].tracker / SCALAR);
    }

    ///=============================================================================================
    /// Pricing
    ///=============================================================================================

    function price(uint256 _count) public view returns (uint256) {
        uint256 pricePerUnit = qtyPricing[pricingVersionCount][_count];
        // Mint more than max discount reverts to max discount
        if (_count > maxWhitelistMintPerTx) {
            pricePerUnit = qtyPricing[pricingVersionCount][
                maxWhitelistMintPerTx
            ];
        }
        // Minting an undefined discount price uses defaults price
        if (pricePerUnit == 0) {
            pricePerUnit = defaultPricePerUnit;
        }
        return pricePerUnit * _count;
    }

    ///=============================================================================================
    /// Whitelist
    ///=============================================================================================

    function whitelistMint(
        uint256 amount,
        uint256 whitelistNonce,
        bytes32 msgHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable returns (uint256[] memory) {
        require(msg.value >= price(amount), "Value below price");
        require(
            !privateMintClaimed[whitelistNonce][msg.sender],
            "Already claimed!"
        );

        // Security check.
        bytes32 calculatedMsgHash = keccak256(
            abi.encodePacked(msg.sender, whitelistNonce)
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
            ),
            _v,
            _r,
            _s
        );
        require(calculatedMsgHash == msgHash, "Invalid hash");
        require(owner == signer, "Access denied");

        // Let's mint!
        privateMintClaimed[whitelistNonce][msg.sender] = true;

        _takeFees();

        uint256[] memory ret = new uint256[](amount);

        for (uint256 i; i < amount; ) {
            ret[i] = _mintNewNFT();
            // unlikely to overflow
            unchecked {
                ++i;
            }
        }

        return ret;
    }

    ///=============================================================================================
    /// Setters
    ///=============================================================================================

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTimeSeconds = _lockTime;
    }

    function setMaxWhiteList(uint256 amount) public onlyOwner {
        maxWhitelistMintPerTx = amount;
    }

    function setMintPrices(
        uint256 _defaultPricePerUnit,
        uint256[] memory qty,
        uint256[] memory prices
    ) public onlyOwner {
        require(
            qty.length == prices.length,
            "Qty input vs price length mismatch"
        );
        defaultPricePerUnit = _defaultPricePerUnit;
        ++pricingVersionCount;

        bool containsMaxWhitelistMintPerTx = false;
        for (uint256 i = 0; i < qty.length; i++) {
            if (qty[i] == maxWhitelistMintPerTx) {
                containsMaxWhitelistMintPerTx = true;
            }
            qtyPricing[pricingVersionCount][qty[i]] = prices[i];
        }
        require(
            containsMaxWhitelistMintPerTx,
            "prices do not include the max mint price"
        );
    }

    function setSupplyCap(uint256 total) external onlyOwner {
        supplyCap = total;
    }

    function setPublicMint(bool open) external onlyOwner {
        publicMint = open;
    }

    ///=============================================================================================
    /// Overrides
    ///=============================================================================================

    string public ipfsLink;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        return string(abi.encodePacked(ipfsLink, tokenId.toString(), ".json"));
    }

    function setTokenUri(string memory baseURI) public onlyOwner {
        ipfsLink = baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return supplyCap;
    }


    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(
            locked[id] == 0 || locked[id] - block.timestamp >= lockTimeSeconds
        );

        locked[id] = 0;

        _removeId(from, id);
        _addId(to, id);

        super.transferFrom(from, to, id);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Owner
/// @notice Transferrable owner authorization pattern.
abstract contract Owner {

    ///===========================
    /// STATE
    ///===========================

    /// @notice Emitted when the ownership is changed
    /// @param previousOwner Previous owner of the contract.
    /// @param newOwner New owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Current owner of the contract.
    address public owner;

    ///@notice Modifier to verify that the sender is the owner of the contract.
    modifier onlyOwner() {
        require (msg.sender == owner, "NOT_OWNER");
        _;
    }

    ///===========================
    /// INIT
    ///===========================

    ///@notice Initially set the owner as the contract deployer.
    constructor() {
        _transferOwnership(msg.sender);
    }

    ///===========================
    /// FUNCTIONS
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    ///===========================
    /// INTERNAL
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";
import {LogisticVRGDA} from "./LogisticVRGDA.sol";

abstract contract LogisticToLinearVRGDA is LogisticVRGDA {
    int256 internal immutable soldBySwitch;

    int256 internal immutable switchTime;

    int256 internal immutable perTimeUnit;

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

    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
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

abstract contract LogisticVRGDA is VRGDA {
    int256 internal immutable logisticLimit;

    int256 internal immutable logisticLimitDoubled;

    int256 internal immutable timeScale;

    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _maxSellable,
        int256 _timeScale
    ) VRGDA(_targetPrice, _priceDecayPercent) {
        logisticLimit = _maxSellable + 1e18;

        logisticLimitDoubled = logisticLimit * 2e18;

        timeScale = _timeScale;
    }

    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimitDoubled, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";


abstract contract VRGDA {
    int256 public immutable targetPrice;

    int256 internal immutable decayConstant;

    constructor(int256 _targetPrice, int256 _priceDecayPercent) {
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (uint256) {
        unchecked {
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1))
            ))));
        }
    }

    function getTargetSaleTime(int256 sold) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract Owned {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract ERC1155 {

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


    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;


    function uri(uint256 id) public view virtual returns (string memory);


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

        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

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

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }


    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || 
            interfaceId == 0xd9b67a26 || 
            interfaceId == 0x0e89341c;
    }

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
        uint256 idsLength = ids.length;

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

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
        uint256 idsLength = ids.length;

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

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

abstract contract ERC20 {

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    string public name;

    string public symbol;

    uint8 public immutable decimals;


    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;


    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;


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


    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

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

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }


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

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract ERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;


    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }


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


    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || 
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f;
    }


    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }


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

library FixedPointMathLib {

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; 

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD);
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD);
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y);
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y);
    }


    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := scalar
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := scalar
                }
                default {
                    z := x
                }

                let half := shr(1, scalar)

                for {
                    n := shr(1, n)
                } n {
                    n := shr(1, n)
                } {
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    let xx := mul(x, x)

                    let xxRound := add(xx, half)

                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    x := div(xxRound, scalar)

                    if mod(n, 2) {
                        let zx := mul(z, x)

                        if iszero(eq(div(zx, x), z)) {
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        let zxRound := add(zx, half)

                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }


    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x 

            z := 181 

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

            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let newFreeMemoryPointer := add(mload(0x40), 160)

            mstore(0x40, newFreeMemoryPointer)

            str := sub(newFreeMemoryPointer, 32)

            mstore(str, 0)

            let end := str

           for { let temp := value } 1 {} {
                str := sub(str, 1)

                mstore8(str, add(48, mod(temp, 10)))

                temp := div(temp, 10)

                if iszero(temp) { break }
            }

            let length := sub(end, str)

            str := sub(str, 32)

            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                let end := add(proof.offset, shl(5, proof.length))

                let offset := proof.offset

                for {} 1 {} {
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    leaf := keccak256(0, 64)

                    offset := add(offset, 32) 
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) 
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

function toWadUnsafe(uint256 x) pure returns (int256 r) {
    assembly {
        r := mul(x, 1000000000000000000)
    }
}

function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    assembly {
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    assembly {
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        r := mul(x, y)

        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        r := mul(x, 1000000000000000000)

        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        if (x <= -42139678854452767551) return 0;

        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        x = (x << 78) / 5**18;

        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        assembly {
            r := sdiv(p, q)
        }

        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

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

        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        assembly {
            r := sdiv(p, q)
        }

        r *= 1677202110996718588342820967067443963516166;
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        r >>= 174;
    }
}

function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    assembly {
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";


library LibZERO {
    using FixedPointMathLib for uint256;

    function computeZEROBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            return lastBalanceWad +

            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( 
               (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";


contract Zero is ERC20("Zero", "ZERO", 18) {
    address public immutable zeroApe;

    address public immutable zeroname;

    error Unauthorized();

    constructor(address _zeroApe, address _zeroname) {
        zeroApe = _zeroApe;
        zeroname = _zeroname;
    }

    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    function mintForApe(address to, uint256 amount) external only(zeroApe) {
        _mint(to, amount);
    }

    function burnForApe(address from, uint256 amount) external only(zeroApe) {
        _burn(from, amount);
    }

    function burnForZeroName(address from, uint256 amount) external only(zeroname) {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LibZERO} from "zero-issuance/LibZERO.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {RandProvider} from "./utils/rand/RandProvider.sol";
import {ApeERC721} from "./utils/token/ApeERC721.sol";

import {Zero} from "./Zero.sol";
import {ZeroName} from "./ZeroName.sol";


contract ZeroApe is ApeERC721, LogisticVRGDA, Owned, ERC1155TokenReceiver {
    using LibString for uint256;
    using FixedPointMathLib for uint256;

    Zero public immutable zero;

    ZeroName public immutable zeroname;

    address public immutable team;

    address public immutable community;

    RandProvider public randProvider;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant MINTLIST_SUPPLY = 2000;

    uint256 public constant LEGENDARY_SUPPLY = 10;

    uint256 public constant TEAM_AMOUNT = 300;

    uint256 public constant COMMUNITY_AMOUNT = 700;

    uint256 public constant RESERVED_SUPPLY = (MAX_SUPPLY - MINTLIST_SUPPLY - LEGENDARY_SUPPLY) / 5;

    uint256 public constant MAX_MINTABLE = MAX_SUPPLY
        - MINTLIST_SUPPLY
        - LEGENDARY_SUPPLY
        - RESERVED_SUPPLY;
    
    bytes32 public immutable PROVENANCE_HASH;

    string public UNREVEALED_URI;

    string public BASE_URI;

    bytes32 public immutable merkleRoot;

    mapping(address => bool) public hasClaimedMintlistApe;

    uint256 public immutable mintStart;

    uint128 public numMintedFromZero;

    uint128 public currentNonLegendaryId;

    uint256 public numMintedForReserves;

    uint256 public constant LEGENDARY_APE_INITIAL_START_PRICE = 69;

    uint256 public constant FIRST_LEGENDARY_APE_ID = MAX_SUPPLY - LEGENDARY_SUPPLY + 1;

    uint256 public constant LEGENDARY_AUCTION_INTERVAL = MAX_MINTABLE / (LEGENDARY_SUPPLY + 1);

    struct LegendaryApeAuctionData {
        uint128 startPrice;
        uint128 numSold;
    }

    LegendaryApeAuctionData public legendaryApeAuctionData;

    struct ApeRevealsData {
        uint64 randomSeed;
        uint64 nextRevealTimestamp;
        uint64 lastRevealedId;
        uint56 toBeRevealed;
        bool waitingForSeed;
    }

    ApeRevealsData public apeRevealsData;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public getCopiesOfZeroApeedByApe;

    mapping(address => uint256) public teamAndCommunityMintedAmount;

    event ZeroBalanceUpdated(address indexed user, uint256 newZeroBalance);

    event ApeClaimed(address indexed user, uint256 indexed apeId);
    event ApePurchased(address indexed user, uint256 indexed apeId, uint256 price);
    event LegendaryApeMinted(address indexed user, uint256 indexed apeId, uint256[] burnedApeIds);
    event ReservedApeMinted(address indexed user, uint256 lastMintedApeId, uint256 numApeEach);
    event teamAndCommunityMinted(address indexed user, uint256 lastMintedApeId, uint256 numApeEach);

    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event RandProviderUpgraded(address indexed user, RandProvider indexed newRandProvider);

    event ApeRevealed(address indexed user, uint256 numApe, uint256 lastRevealedId);

    event ZeroApeed(address indexed user, uint256 indexed apeId, address indexed nft, uint256 id);

    error InvalidProof();
    error AlreadyClaimed();
    error MintStartPending();
    error teamAndCommunityMintErr();

    error SeedPending();
    error RevealsPending();
    error RequestTooEarly();
    error ZeroToBeRevealed();
    error NotRandProvider();

    error ReserveImbalance();

    error Cannibalism();
    error OwnerMismatch(address owner);

    error NoRemainingLegendaryApe();
    error CannotBurnLegendary(uint256 apeId);
    error InsufficientApeAmount(uint256 cost);
    error LegendaryAuctionNotStarted(uint256 apeLeft);

    error PriceExceededMax(uint256 currentPrice);

    error NotEnoughRemainingToBeRevealed(uint256 totalRemainingToBeRevealed);

    error UnauthorizedCaller(address caller);

    constructor(
        bytes32 _merkleRoot,
        uint256 _mintStart,
        Zero _zero,
        ZeroName _zeroname,
        address _team,
        address _community,
        RandProvider _randProvider,
        string memory _baseUri,
        string memory _unrevealedUri,
        bytes32 _provenanceHash
    )
        ApeERC721("Zero Ape", "APE")
        Owned(msg.sender)
        LogisticVRGDA(
            69.42e18,
            0.31e18,
            toWadUnsafe(MAX_MINTABLE),
            0.0023e18
        )
    {
        mintStart = _mintStart;
        merkleRoot = _merkleRoot;

        zero = _zero;
        zeroname = _zeroname;
        team = _team;
        community = _community;
        randProvider = _randProvider;

        BASE_URI = _baseUri;
        UNREVEALED_URI = _unrevealedUri;

        PROVENANCE_HASH = _provenanceHash;

        legendaryApeAuctionData.startPrice = uint128(LEGENDARY_APE_INITIAL_START_PRICE);

        apeRevealsData.nextRevealTimestamp = uint64(_mintStart + 1 days);
    }

    function claimApe(bytes32[] calldata proof) external returns (uint256 apeId) {
        if (mintStart > block.timestamp) revert MintStartPending();

        if (hasClaimedMintlistApe[msg.sender]) revert AlreadyClaimed();

        if (!MerkleProofLib.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        hasClaimedMintlistApe[msg.sender] = true;

        unchecked {
            emit ApeClaimed(msg.sender, apeId = ++currentNonLegendaryId);
        }

        _mint(msg.sender, apeId);
    }


    function mintFromZero(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 apeId) {
        uint256 currentPrice = apePrice();

        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        useVirtualBalance
            ? updateUserZeroBalance(msg.sender, currentPrice, ZeroBalanceUpdateType.DECREASE)
            : zero.burnForApe(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromZero; 

            emit ApePurchased(msg.sender, apeId = ++currentNonLegendaryId, currentPrice);
        }

        _mint(msg.sender, apeId);
    }

    function apePrice() public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), numMintedFromZero);
    }

    
    function mintLegendaryApe(uint256[] calldata apeIds) external returns (uint256 apeId) {
        uint256 numSold = legendaryApeAuctionData.numSold;

        apeId = FIRST_LEGENDARY_APE_ID + numSold;

        uint256 cost = legendaryApePrice();

        if (apeIds.length < cost) revert InsufficientApeAmount(cost);

        unchecked {
            uint256 burnedMultipleTotal;

            uint256 id;

            for (uint256 i = 0; i < cost; ++i) {
                id = apeIds[i];

                if (id >= FIRST_LEGENDARY_APE_ID) revert CannotBurnLegendary(id);

                ApeData storage ape = getApeData[id];

                require(ape.owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += ape.emissionMultiple;

                delete getApproved[id];

                emit Transfer(msg.sender, ape.owner = address(0), id);
            }

            getApeData[apeId].emissionMultiple = uint32(burnedMultipleTotal * 2);

            getUserData[msg.sender].lastBalance = uint128(zeroBalance(msg.sender));
            getUserData[msg.sender].lastTimestamp = uint64(block.timestamp);
            getUserData[msg.sender].emissionMultiple += uint32(burnedMultipleTotal);
            getUserData[msg.sender].apeOwned -= uint32(cost);

            legendaryApeAuctionData.startPrice = uint128(
                cost <= LEGENDARY_APE_INITIAL_START_PRICE / 2 ? LEGENDARY_APE_INITIAL_START_PRICE : cost * 2
            );
            legendaryApeAuctionData.numSold = uint128(numSold + 1); // Increment the # of legendaries sold.

            emit LegendaryApeMinted(msg.sender, apeId, apeIds[:cost]);

            _mint(msg.sender, apeId);
        }
    }

    function legendaryApePrice() public view returns (uint256) {
        uint256 startPrice = legendaryApeAuctionData.startPrice;
        uint256 numSold = legendaryApeAuctionData.numSold;

        if (numSold == LEGENDARY_SUPPLY) revert NoRemainingLegendaryApe();

        unchecked {
            uint256 mintedFromZero = numMintedFromZero;

            uint256 numMintedAtStart = (numSold + 1) * LEGENDARY_AUCTION_INTERVAL;

            if (numMintedAtStart > mintedFromZero) revert LegendaryAuctionNotStarted(numMintedAtStart - mintedFromZero);

            uint256 numMintedSinceStart = mintedFromZero - numMintedAtStart;

            if (numMintedSinceStart >= LEGENDARY_AUCTION_INTERVAL) return 0;
            else return FixedPointMathLib.unsafeDivUp(startPrice * (LEGENDARY_AUCTION_INTERVAL - numMintedSinceStart), LEGENDARY_AUCTION_INTERVAL);
        }
    }

    function requestRandomSeed() external returns (bytes32) {
        uint256 nextRevealTimestamp = apeRevealsData.nextRevealTimestamp;

        if (block.timestamp < nextRevealTimestamp) revert RequestTooEarly();

        if (apeRevealsData.toBeRevealed != 0) revert RevealsPending();

        unchecked {
            apeRevealsData.waitingForSeed = true;

            uint256 toBeRevealed = currentNonLegendaryId - apeRevealsData.lastRevealedId;

            if (toBeRevealed == 0) revert ZeroToBeRevealed();

            apeRevealsData.toBeRevealed = uint56(toBeRevealed);

            apeRevealsData.nextRevealTimestamp = uint64(nextRevealTimestamp + 1 days);

            emit RandomnessRequested(msg.sender, toBeRevealed);
        }

        return randProvider.requestRandomBytes();
    }

    function acceptRandomSeed(bytes32, uint256 randomness) external {
        if (msg.sender != address(randProvider)) revert NotRandProvider();

        apeRevealsData.randomSeed = uint64(randomness);

        apeRevealsData.waitingForSeed = false;

        emit RandomnessFulfilled(randomness);
    }

    function upgradeRandProvider(RandProvider newRandProvider) external onlyOwner {
        if (apeRevealsData.waitingForSeed) {
            apeRevealsData.waitingForSeed = false;
            apeRevealsData.toBeRevealed = 0;
            apeRevealsData.nextRevealTimestamp -= 1 days;
        }

        randProvider = newRandProvider;

        emit RandProviderUpgraded(msg.sender, newRandProvider);
    }

    function revealApe(uint256 numApe) external {
        uint256 randomSeed = apeRevealsData.randomSeed;

        uint256 lastRevealedId = apeRevealsData.lastRevealedId;

        uint256 totalRemainingToBeRevealed = apeRevealsData.toBeRevealed;

        if (apeRevealsData.waitingForSeed) revert SeedPending();

        if (numApe > totalRemainingToBeRevealed) revert NotEnoughRemainingToBeRevealed(totalRemainingToBeRevealed);

        unchecked {
            for (uint256 i = 0; i < numApe; ++i) {
                uint256 remainingIds = FIRST_LEGENDARY_APE_ID - lastRevealedId - 1;

                uint256 distance = randomSeed % remainingIds;

                uint256 currentId = ++lastRevealedId;

                uint256 swapId = currentId + distance;

                uint64 swapIndex = getApeData[swapId].idx == 0
                    ? uint64(swapId)
                    : getApeData[swapId].idx;

                address currentIdOwner = getApeData[currentId].owner;

                uint64 currentIndex = getApeData[currentId].idx == 0
                    ? uint64(currentId)
                    : getApeData[currentId].idx;

                uint256 newCurrentIdMultiple = 9;

                assembly {
                    newCurrentIdMultiple := sub(sub(sub(
                        newCurrentIdMultiple,
                        lt(swapIndex, 7964)),
                        lt(swapIndex, 5673)),
                        lt(swapIndex, 3055)
                    )
                }

                getApeData[currentId].idx = swapIndex;
                getApeData[currentId].emissionMultiple = uint32(newCurrentIdMultiple);

                getApeData[swapId].idx = currentIndex;

                getUserData[currentIdOwner].lastBalance = uint128(zeroBalance(currentIdOwner));
                getUserData[currentIdOwner].lastTimestamp = uint64(block.timestamp);
                getUserData[currentIdOwner].emissionMultiple += uint32(newCurrentIdMultiple);

                assembly {
                    mstore(0, randomSeed)

                    randomSeed := mod(keccak256(0, 32), exp(2, 64))
                }
            }

            apeRevealsData.randomSeed = uint64(randomSeed);
            apeRevealsData.lastRevealedId = uint64(lastRevealedId);
            apeRevealsData.toBeRevealed = uint56(totalRemainingToBeRevealed - numApe);

            emit ApeRevealed(msg.sender, numApe, lastRevealedId);
        }
    }

    function tokenURI(uint256 apeId) public view virtual override returns (string memory) {
        if (apeId <= apeRevealsData.lastRevealedId) {
            if (apeId == 0) revert("NOT_MINTED"); // 0 is not a valid id for Zero Ape.

            return string.concat(BASE_URI, uint256(getApeData[apeId].idx).toString());
        }

        if (apeId <= currentNonLegendaryId) return UNREVEALED_URI;

        if (apeId < FIRST_LEGENDARY_APE_ID) revert("NOT_MINTED");

        if (apeId < FIRST_LEGENDARY_APE_ID + legendaryApeAuctionData.numSold)
            return string.concat(BASE_URI, apeId.toString());

        revert("NOT_MINTED");
    }

    function ape(
        uint256 apeId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        address owner = getApeData[apeId].owner;

        if (owner != msg.sender) revert OwnerMismatch(owner);

        if (nft == address(this)) revert Cannibalism();

        unchecked {
            ++getCopiesOfZeroApeedByApe[apeId][nft][id];
        }

        emit ZeroApeed(msg.sender, apeId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "")
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }

   function zeroBalance(address user) public view returns (uint256) {
        return LibZERO.computeZEROBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].lastBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    function addZero(uint256 zeroAmount) external {
        zero.burnForApe(msg.sender, zeroAmount);

        updateUserZeroBalance(msg.sender, zeroAmount, ZeroBalanceUpdateType.INCREASE);
    }

    function removeZero(uint256 zeroAmount) external {
        updateUserZeroBalance(msg.sender, zeroAmount, ZeroBalanceUpdateType.DECREASE);

        zero.mintForApe(msg.sender, zeroAmount);
    }

    function burnZeroForZeroName(address user, uint256 zeroAmount) external {
        if (msg.sender != address(zeroname)) revert UnauthorizedCaller(msg.sender);

        updateUserZeroBalance(user, zeroAmount, ZeroBalanceUpdateType.DECREASE);
    }

    enum ZeroBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    function updateUserZeroBalance(
        address user,
        uint256 zeroAmount,
        ZeroBalanceUpdateType updateType
    ) internal {
        uint256 updatedBalance = updateType == ZeroBalanceUpdateType.INCREASE
            ? zeroBalance(user) + zeroAmount
            : zeroBalance(user) - zeroAmount;

        getUserData[user].lastBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint64(block.timestamp);

        emit ZeroBalanceUpdated(user, updatedBalance);
    }

    function mintReservedApe(uint256 numApeEach) external returns (uint256 lastMintedApeId) {
        unchecked {
            uint256 newNumMintedForReserves = numMintedForReserves += (numApeEach * 2);

            if (newNumMintedForReserves > (numMintedFromZero + newNumMintedForReserves) / 5) revert ReserveImbalance();
        }

        lastMintedApeId = _batchMint(team, numApeEach, currentNonLegendaryId);
        lastMintedApeId = _batchMint(community, numApeEach, lastMintedApeId);

        currentNonLegendaryId = uint128(lastMintedApeId); // Set currentNonLegendaryId.

        emit ReservedApeMinted(msg.sender, lastMintedApeId, numApeEach);
    }

    function teamAndCommunityMint(address to, uint256 amount) external onlyOwner {
        uint256 alreadyAmount = teamAndCommunityMintedAmount[to];
        if (to == team && alreadyAmount < TEAM_AMOUNT) {
            privateMint(team, alreadyAmount, amount, TEAM_AMOUNT);
        } else if (to == community && alreadyAmount < COMMUNITY_AMOUNT) {
            privateMint(community, alreadyAmount, amount, COMMUNITY_AMOUNT);
        } else {
            revert teamAndCommunityMintErr();
        }    
    }

    function privateMint(
        address sender,
        uint256 alreadyAmount, 
        uint256 amount, 
        uint256 maxAmount
    ) internal onlyOwner returns (uint256 lastMintedApeId) {
        if (alreadyAmount + amount <= maxAmount) {
            teamAndCommunityMintedAmount[sender] += amount;
            lastMintedApeId = _batchMint(sender, amount, currentNonLegendaryId);
            currentNonLegendaryId = uint128(lastMintedApeId);
            emit teamAndCommunityMinted(msg.sender, lastMintedApeId, amount);
        } else {
            teamAndCommunityMintedAmount[sender] = maxAmount;
            lastMintedApeId = _batchMint(sender, maxAmount - alreadyAmount, currentNonLegendaryId);
            currentNonLegendaryId = uint128(lastMintedApeId);
            emit teamAndCommunityMinted(msg.sender, lastMintedApeId, maxAmount - alreadyAmount);
        }
    }

    function getApeEmissionMultiple(uint256 apeId) external view returns (uint256) {
        return getApeData[apeId].emissionMultiple;
    }

    function getUserEmissionMultiple(address user) external view returns (uint256) {
        return getUserData[user].emissionMultiple;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        require(from == getApeData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        delete getApproved[id];

        getApeData[id].owner = to;

        unchecked {
            uint32 emissionMultiple = getApeData[id].emissionMultiple; 

            getUserData[from].lastBalance = uint128(zeroBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);
            getUserData[from].emissionMultiple -= emissionMultiple;
            getUserData[from].apeOwned -= 1;

            getUserData[to].lastBalance = uint128(zeroBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
            getUserData[to].emissionMultiple += emissionMultiple;
            getUserData[to].apeOwned += 1;
        }

        emit Transfer(from, to, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LibString} from "solmate/utils/LibString.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LogisticToLinearVRGDA} from "VRGDAs/LogisticToLinearVRGDA.sol";

import {ZeroNameERC721} from "./utils/token/ZeroNameERC721.sol";

import {Zero} from "./Zero.sol";
import {ZeroApe} from "./ZeroApe.sol";

contract ZeroName is ZeroNameERC721, LogisticToLinearVRGDA {
    using LibString for uint256;

    Zero public immutable zero;

    address public immutable community;

    string public BASE_URI;

    uint256 public immutable mintStart;

    uint128 public currentId;

    uint128 public numMintedForCommunity;

    int256 internal constant SWITCH_DAY_WAD = 233e18;

    int256 internal constant SOLD_BY_SWITCH_WAD = 8336.760939794622713006e18;


    event ZeroNamePurchased(address indexed user, uint256 indexed zeronameId, uint256 price);

    event CommunityZeroNameMinted(address indexed user, uint256 lastMintedZeroNameId, uint256 numZeroName);

    error ReserveImbalance();

    error PriceExceededMax(uint256 currentPrice);

    constructor(
        uint256 _mintStart,
        Zero _zero,
        address _community,
        ZeroApe _zeroApe,
        string memory _baseUri
    )
        ZeroNameERC721(_zeroApe, "ZeroName", "ZERONAME")
        LogisticToLinearVRGDA(
            4.2069e18, 
            0.31e18,
            9000e18,
            0.014e18,
            SOLD_BY_SWITCH_WAD,
            SWITCH_DAY_WAD,
            9e18
        )
    {
        mintStart = _mintStart;

        zero = _zero;

        community = _community;

        BASE_URI = _baseUri;
    }

    function mintFromZero(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 zeronameId) {
        uint256 currentPrice = zeronamePrice();

        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        useVirtualBalance
            ? zeroApe.burnZeroForZeroName(msg.sender, currentPrice)
            : zero.burnForZeroName(msg.sender, currentPrice);

        unchecked {
            emit ZeroNamePurchased(msg.sender, zeronameId = ++currentId, currentPrice);

            _mint(msg.sender, zeronameId);
        }
    }

    function zeronamePrice() public view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - mintStart;

        unchecked {
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), currentId - numMintedForCommunity);
        }
    }

    function mintCommunityZeroName(uint256 numZeroName) external returns (uint256 lastMintedZeroNameId) {
        unchecked {
            uint256 newNumMintedForCommunity = numMintedForCommunity += uint128(numZeroName);

            if (newNumMintedForCommunity > ((lastMintedZeroNameId = currentId) + numZeroName) / 10) revert ReserveImbalance();

            lastMintedZeroNameId = _batchMint(community, numZeroName, lastMintedZeroNameId);

            currentId = uint128(lastMintedZeroNameId);
            emit CommunityZeroNameMinted(msg.sender, lastMintedZeroNameId, numZeroName);
        }
    }

    function tokenURI(uint256 zeronameId) public view virtual override returns (string memory) {
        if (zeronameId == 0 || zeronameId > currentId) revert("NOT_MINTED");

        return string.concat(BASE_URI, zeronameId.toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";

import {ZeroApe} from "../ZeroApe.sol";

contract ApeReserve is Owned {
    ZeroApe public immutable zeroApe;

    constructor(ZeroApe _zeroApe, address _owner) Owned(_owner) {
        zeroApe = _zeroApe;
    }

    function withdraw(address to, uint256[] calldata ids) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                zeroApe.transferFrom(address(this), to, ids[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface RandProvider {
    event RandomBytesRequested(bytes32 requestId);
    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    function requestRandomBytes() external returns (bytes32 requestId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

abstract contract ApeERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    struct ApeData {
        address owner;
        uint64 idx;
        uint32 emissionMultiple;
    }

    mapping(uint256 => ApeData) public getApeData;

    struct UserData {
        uint32 apeOwned;
        uint32 emissionMultiple;
        uint128 lastBalance;
        uint64 lastTimestamp;
    }

    mapping(address => UserData) public getUserData;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = getApeData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return getUserData[owner].apeOwned;
    }

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function approve(address spender, uint256 id) external {
        address owner = getApeData[id].owner;

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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || 
            interfaceId == 0x80ac58cd || 
            interfaceId == 0x5b5e139f;
    }

    function _mint(address to, uint256 id) internal {
        unchecked {
            ++getUserData[to].apeOwned;
        }

        getApeData[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId
    ) internal returns (uint256) {
        unchecked {
            getUserData[to].apeOwned += uint32(amount);

            for (uint256 i = 0; i < amount; ++i) {
                getApeData[++lastMintedId].owner = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ZeroApe} from "../../ZeroApe.sol";

abstract contract ZeroNameERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    ZeroApe public immutable zeroApe;

    constructor(
        ZeroApe _zeroApe,
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        zeroApe = _zeroApe;
    }

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }


    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) internal _isApprovedForAll;

    function isApprovedForAll(address owner, address operator) public view returns (bool isApproved) {
        if (operator == address(zeroApe)) return true; 

        return _isApprovedForAll[owner][operator];
    }

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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || 
            interfaceId == 0x80ac58cd || 
            interfaceId == 0x5b5e139f; 

    }
    
    function _mint(address to, uint256 id) internal {
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
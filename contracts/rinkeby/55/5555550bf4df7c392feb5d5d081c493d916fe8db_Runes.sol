// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "./ERC721.sol";
import {Base64} from "./Base64.sol";

contract Runes is ERC721 {
    uint256 public constant RUNE_OF_POWER = 1;
    uint256 public constant RUNE_OF_WEALTH = 2;
    uint256 public constant RUNE_OF_TIME = 3;
    uint256 public constant RUNE_OF_SPACE = 4;
    uint256 public constant RUNE_OF_INFLUENCE = 5;

    uint256 public lastPrice;
    uint256 public lastPower;
    uint256 public lastTime;
    uint256 public cooldown = 1 days;
    uint256 public lastBasefee;
    uint256 public lastVotes;

    mapping(address => mapping(uint256 => address)) public nominations;
    mapping(address => uint256) public votes;

    address public creator;

    constructor() ERC721("Runes", "RUNES") {
        _mint(msg.sender, RUNE_OF_POWER);
        _mint(msg.sender, RUNE_OF_WEALTH);
        _mint(msg.sender, RUNE_OF_TIME);
        _mint(msg.sender, RUNE_OF_SPACE);
        _mint(msg.sender, RUNE_OF_INFLUENCE);

        creator = msg.sender;
    }

    function claimRuneOfPower(uint256 nonce) external {
        uint256 power = uint256(
            keccak256(abi.encodePacked(lastPower, nonce, msg.sender))
        );
        require(power > lastPower, "Not powerful enough");
        lastPower = power;

        _transfer(ownerOf(RUNE_OF_POWER), msg.sender, RUNE_OF_POWER);
    }

    function claimRuneOfWealth() external payable {
        require(msg.value > lastPrice, "Insufficient payment");

        address lastClaimer = ownerOf(RUNE_OF_WEALTH);
        uint256 refund = lastPrice;
        uint256 gift = address(this).balance - refund;

        _transfer(lastClaimer, msg.sender, RUNE_OF_WEALTH);
        lastPrice = msg.value;

        bool success = payable(lastClaimer).send(refund);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: refund}();
            require(weth.transfer(lastClaimer, refund), "Payment failed");
        }

        payable(creator).transfer(gift);
    }

    function claimRuneOfTime() external {
        require(block.timestamp > lastTime + cooldown, "Need to wait");
        lastTime = block.timestamp;
        cooldown = cooldown + cooldown / 10;
        _transfer(ownerOf(RUNE_OF_TIME), msg.sender, RUNE_OF_TIME);
    }

    function claimRuneOfSpace() external {
        require(block.basefee > lastBasefee, "Block space not dense enough");
        lastBasefee = block.basefee;
        _transfer(ownerOf(RUNE_OF_SPACE), msg.sender, RUNE_OF_SPACE);
    }

    function nominate(
        address collection,
        uint256 tokenId,
        address who
    ) external {
        require(
            collection == 0x4D2BB1FDfBdd3e5aC720a4c557117daB75351bfC ||
                collection == 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7 ||
                collection == 0x5180db8F5c931aaE63c74266b211F580155ecac8 ||
                collection == 0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63,
            "Not from this universe"
        );
        require(
            IERC721Ownership(collection).ownerOf(tokenId) == msg.sender,
            "Not authorized"
        );

        address prev = nominations[collection][tokenId];
        if (prev != address(0)) {
            votes[prev] -= 1;
        }

        nominations[collection][tokenId] = who;
        votes[who] += 1;

        if (votes[who] > lastVotes) {
            lastVotes = votes[who];
            _transfer(ownerOf(RUNE_OF_INFLUENCE), who, RUNE_OF_INFLUENCE);
        }
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        string[5] memory names = [
            "Power",
            "Wealth",
            "Time",
            "Space",
            "Influence"
        ];
        string[5] memory paths = [
            "M137 260V90l76 47v123",
            "M155 78v195m-1-153 42-42m-42 94 73-73",
            "m172 260-60-62 49-48m29 50 48-53-54-57",
            "m140 252 74-76-74-78m72 0-76 77 76 76",
            "m165 142 51 30m-52 85V94l55 38"
        ];
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000">',
            '<path d="',
            paths[id - 1],
            '" stroke="#fff" stroke-width="15"/>',
            "</svg>"
        );
        string memory json = string.concat(
            '{"name":"Rune of ',
            names[id - 1],
            '","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }
}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address who) external returns (uint256);
}

interface IERC721Ownership {
    function ownerOf(uint256 tokenId) external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        _transfer(from, to, id);
    }

    function _transfer(
        address from,
        address to,
        uint256 id
    ) internal {
        _balanceOf[from]--;
        _balanceOf[to]++;

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
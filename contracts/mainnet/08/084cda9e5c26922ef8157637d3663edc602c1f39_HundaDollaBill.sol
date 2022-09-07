// SPDX-License-Identifier: UNLICENSED

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.13;

import "solmate/tokens/ERC721.sol";

interface ERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address operator, uint256 allowance) external;

    function balanceOf(address user) external returns (uint256);
}

interface IPrizePool {
    function depositTo(address to, uint256 amount) external;
    function withdrawFrom(address from, uint256 amount) external returns (uint256);
}

error PleaseReturnDuringBusinessHours();
error ExceededMaxDeposit();
error YouDontOwnThisHDB(uint256 tokenId);
error PoolTogetherIsFuckingUp();
error NotJesus();
error CantRug();

contract HundaDollaBill is ERC721 {
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant pooltogetherV4 = 0xd89a09084555a7D0ABe7B111b1f78DFEdDd638Be;
    address public constant PTaUSDC = 0xdd4d117723C257CEe402285D3aCF218E9A8236E1;
    address public immutable JESUS;
    uint256 public currentSerialId;
    uint256 public currentSupply;
    uint256 public constant DAY_IN_SECONDS = 86400;

    modifier onlyBusinessDays() {
        uint256 weekday = getWeekday(block.timestamp);
        if (weekday == 0 || weekday == 6) {
            revert PleaseReturnDuringBusinessHours();
        }
        _;
    }

    constructor() ERC721("Hunda Dolla Bill", "HDB") {
        JESUS = msg.sender;
        ERC20(USDC).approve(pooltogetherV4, type(uint256).max);
    }

    function mint(uint256 amount) external onlyBusinessDays {
        if (amount > 30) {
            revert ExceededMaxDeposit();
        }
        unchecked {
            uint256 usdcAmount = 100000000 * amount;
            ERC20(USDC).transferFrom(msg.sender, address(this), usdcAmount);
            IPrizePool(pooltogetherV4).depositTo(address(this), usdcAmount);
            currentSupply += amount;
        }
        uint256 tempSerialId = currentSerialId;
        for (uint256 i = 0; i < amount;) {
            unchecked {
                _mint(msg.sender, tempSerialId++);
                i++;
            }
        }
        currentSerialId = tempSerialId;
    }

    function burn(uint256[] calldata tokenIds) external onlyBusinessDays {
        for (uint256 i = 0; i < tokenIds.length;) {
            if (ownerOf(tokenIds[i]) != msg.sender) {
                revert YouDontOwnThisHDB(tokenIds[i]);
            }
            _burn(tokenIds[i]);
            unchecked {
                i++;
            }
        }
        unchecked {
            uint256 usdcAmount = 100000000 * tokenIds.length;

            uint256 amountWithdrawn = IPrizePool(pooltogetherV4).withdrawFrom(address(this), usdcAmount);
            if (amountWithdrawn != usdcAmount) {
                revert PoolTogetherIsFuckingUp();
            }

            ERC20(USDC).transfer(msg.sender, usdcAmount);
            currentSupply -= tokenIds.length;
        }
    }

    /**
     * @notice lets JESUS withdraw any erc20 token EXCEPT PTaUSDC. NO RUG PULL FOR JESUS
     */
    function rescueERC20(address tokenAddress, uint256 amount) external onlyBusinessDays {
        if (msg.sender != JESUS) {
            revert NotJesus();
        }
        uint256 balance = ERC20(tokenAddress).balanceOf(address(this));
        if (
            tokenAddress == PTaUSDC && 
            ((balance - amount) > (currentSupply * 100000000))
        ) {
            revert CantRug();
        }
        ERC20(tokenAddress).transfer(JESUS, amount);
    }

    /**
     * @notice lets JESUS withdraw ETH. ape proof
     */
    function rescueETH() external onlyBusinessDays {
        if (msg.sender != JESUS) {
            revert NotJesus();
        }
        (bool succ,) = JESUS.call{value: address(this).balance}("");
        require(succ);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Hunda Dolla Bill #',
                        toString(tokenId),
                        '","description": "The Hunda Dolla Bill note features additional security features including a 3-D Security Ribbon and color-shifting Bell in the Inkwell. To report a counterfeit note, please visit the following website: https://www.uscurrency.gov/report-counterfeit", "image": "ipfs://QmcDN3saeUf7NMG5KkpqbHDdGqfTru17b5bZDyh7cqPFNk", "animation_url": "ipfs://QmfCP7beeJw8u9n4itPZH6a72wwy2TuT8gZCrMXZg1JRhf"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        unchecked {
            return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }
    }

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
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) {
            return "";
        }

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
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
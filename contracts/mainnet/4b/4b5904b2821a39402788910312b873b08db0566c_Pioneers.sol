/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

/// [MIT License]
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
}/// @title ERC20 Interface
/// @dev https://eips.ethereum.org/EIPS/eip-20
/// @author Andreas Bigger <[email protected]>
interface IERC20 {
    /// @dev The circulating supply of tokens
    function totalSupply() external view returns (uint256);

    /// @dev The number of tokens owned by the account
    /// @param account The address to get the balance for
    function balanceOf(address account) external view returns (uint256);

    /// @dev Transfers the specified amount of tokens to the recipient from the sender
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @dev The amount of tokens the spender is permitted to transfer from the owner
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Permits a spender to transfer an amount of tokens
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev Transfers tokens from the sender using the caller's allowance
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev Emitted when tokens are transfered
    /// @param from The address that is sending the tokens
    /// @param to The token recipient
    /// @param value The number of tokens
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when an owner permits a spender
    /// @param owner The token owner
    /// @param spender The permitted spender
    /// @param value The number of tokens
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
////////////////////////////////////////////////
///                                          ///
///         /|\                /|\           ///
///        |||||              |||||          ///
///        |||||              |||||          ///
///    /\  |||||          /\  |||||          ///
///   |||| |||||         |||| |||||          ///
///   |||| |||||  /\     |||| |||||  /\      ///
///   |||| ||||| ||||    |||| ||||| ||||     ///
///    \|`-'|||| ||||     \|`-'|||| ||||     ///
///     \__ |||| ||||      \__ |||| ||||     ///
///        ||||`-'|||         ||||`-'|||     ///
///        |||| ___/          |||| ___/      ///
///        |||||              |||||          ///
///        |||||              |||||          ///
///   ------------------------------------   ///
///                                          ///
////////////////////////////////////////////////

/// @title Pioneers
/// @notice An NFT for early Yobot Adopters
/// @author Andreas Bigger <[email protected]>
/// @dev Opensea gasless listings logic adapted from Crypto Covens
/// @dev Ref: https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
contract Pioneers is ERC721 {

    /// ~~~~~~~~~~~~~~~~~~~~~~ CUSTOM ERRORS ~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @notice Maximum number of tokens minted
    error MaximumMints();

    /// @notice Too few tokens remain
    error InsufficientTokensRemain();

    /// @notice Not enough ether sent to mint
    error InsufficientFunds();

    /// @notice Caller is not the contract owner
    error Unauthorized();

    /// @notice Thrown if the user has already minted this token
    error AlreadyMinted();

    /// @notice Thrown when the sale is closed
    error MintClosed();

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~ STORAGE ~~~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @dev Number of tokens
    uint8 public tokenCount;

    /// @notice The contract Owner
    address public owner;

    /// @notice Sale Active?
    bool public isPublicSaleActive;

    /// @notice Allowed mints per wallet
    mapping(address => bool) public minted;

    /// @notice The maximum number of nfts to mint
    uint256 public constant MAXIMUM_COUNT = 100;

    /// @notice The maximum number of tokens to mint per wallet
    uint256 public constant MAX_TOKENS_PER_WALLET = 1;

    /// @notice Cost to mint a token
    uint256 public constant PUBLIC_SALE_PRICE = 0.05 ether;

    /// ~~~~~~~~~~~~~~~~~~~~~~~~ MODIFIERS ~~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @dev Checks if there are enough tokens left for minting
    modifier canMint() {
      if (tokenCount >= MAXIMUM_COUNT) {
        revert MaximumMints();
      }
      if (tokenCount + 1 > MAXIMUM_COUNT) {
        revert InsufficientTokensRemain();
      }
      if (minted[msg.sender]) {
        revert AlreadyMinted();
      }
      _;
    }

    /// @dev Checks if user sent enough ether to mint
    modifier isCorrectPayment() {
      if (PUBLIC_SALE_PRICE > msg.value) {
        revert InsufficientFunds();
      }
      _;
    }

    /// @dev Checks if the message sender is the contract owner
    modifier onlyOwner() {
      if (msg.sender != owner) {
        revert Unauthorized();
      }
      _;
    }

    /// @dev Checks if minting is enabled
    modifier isMintingOpen() {
      if (!isPublicSaleActive) {
        revert MintClosed();
      }
      _;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~ CONSTRUCTOR ~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @notice Creates the ERC721 with the predefined metadata
    constructor() ERC721("Pioneers", "PINR") {
      owner = msg.sender;
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~~~ METADATA ~~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @notice Returns the URI for the given token
    /// @param tokenId The token id to query against
    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      string memory baseSvg =
        "<svg viewBox='0 0 800 800' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>"
        "<style>.text--line{font-size:400px;font-weight:bold;font-family:'Arial';}"
        ".top-text{fill:#bafe49;font-weight: bold;font-color:#bafe49;font-size:40px;font-family:'Arial';}"
        ".text-copy{fill:none;stroke:white;stroke-dasharray:25% 40%;stroke-width:4px;animation:stroke-offset 9s infinite linear;}"
        ".text-copy:nth-child(1){stroke:#bafe49;stroke-dashoffset:6% * 1;}.text-copy:nth-child(2){stroke:#bafe49;stroke-dashoffset:6% * 2;}"
        ".text-copy:nth-child(3){stroke:#bafe49;stroke-dashoffset:6% * 3;}.text-copy:nth-child(4){stroke:#bafe49;stroke-dashoffset:6% * 4;}"
        ".text-copy:nth-child(5){stroke:#bafe49;stroke-dashoffset:6% * 5;}.text-copy:nth-child(6){stroke:#bafe49;stroke-dashoffset:6% * 6;}"
        ".text-copy:nth-child(7){stroke:#bafe49;stroke-dashoffset:6% * 7;}.text-copy:nth-child(8){stroke:#bafe49;stroke-dashoffset:6% * 8;}"
        ".text-copy:nth-child(9){stroke:#bafe49;stroke-dashoffset:6% * 9;}.text-copy:nth-child(10){stroke:#bafe49;stroke-dashoffset:6% * 10;}"
        "@keyframes stroke-offset{45%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}60%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}}"
        "</style>"
        "<rect width='100%' height='100%' fill='black' />"
        "<symbol id='s-text'>"
        "<text text-anchor='middle' x='50%' y='70%' class='text--line'>Y</text>"
        "</symbol><g class='g-ants'>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use>"
        "<use href='#s-text' class='text-copy'></use></g>";

      // Convert token id to string
      string memory sTokenId = toString(tokenId);

      // Create the SVG Image
      string memory finalSvg = string(
        abi.encodePacked(
          baseSvg,
          "<text class='top-text' margin='2px' x='4%' y='8%'>",
          sTokenId,
          "</text></svg>"
        )
      );

      // Base64 Encode our JSON Metadata
      string memory json = Base64.encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "Pioneer ',
              sTokenId,
              '", "description": "',
              'Number ',
              sTokenId,
              ' of the Pioneer collection for early Yobot Adopters", "image": "data:image/svg+xml;base64,',
              Base64.encode(bytes(finalSvg)),
              '"}'
            )
          )
        )
      );

      // Prepend data:application/json;base64 to define the base64 encoded data
      return string(
        abi.encodePacked("data:application/json;base64,", json)
      );
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ MINTING LOGIC ~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @notice Permissionless minting
    /// @param to The address to mint to
    function mint(address to)
      public
      virtual
      payable
      isCorrectPayment
      canMint
      isMintingOpen
    {
      uint256 tokenId = uint256(tokenCount);
      unchecked { ++tokenCount; }
      minted[msg.sender] = true;
      _mint(to, tokenId);
    }

    /// @notice Allows the owner to mint tokens
    /// @param to The address to mint to
    function privateMint(address to) public virtual payable onlyOwner {
      uint256 tokenId = uint256(tokenCount);
      unchecked { ++tokenCount; }
      _mint(to, tokenId);
    }

    /// @notice Permissionless minting with safe receiver checks
    /// @param to The address to mint to
    function safeMint(address to)
      public
      virtual
      payable
      isCorrectPayment
      canMint
      isMintingOpen
    {
      uint256 tokenId = uint256(tokenCount);
      unchecked { ++tokenCount; }
      minted[msg.sender] = true;
      _safeMint(to, tokenId);
    }

    /// @notice Permissionless minting with safe receiver checks and calldata
    /// @param to The address to mint to
    /// @param data Data to forward to the token receiver
    function safeMint(
      address to,
      bytes memory data
    )
      public
      virtual
      payable
      isCorrectPayment
      canMint
      isMintingOpen
    {
      uint256 tokenId = uint256(tokenCount);
      unchecked { ++tokenCount; }
      minted[msg.sender] = true;
      _safeMint(to, tokenId, data);
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~~ ADMIN LOGIC ~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @dev Sets if the sale is active
    /// @param _isPublicSaleActive Whether the public sale is open or not
    function setIsPublicSaleActive(bool _isPublicSaleActive)
      external
      onlyOwner
    {
      isPublicSaleActive = _isPublicSaleActive;
    }

    /// @dev Allows the owner to withdraw eth
    function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      (bool sent,) = msg.sender.call{value: balance}("");
      require(sent, "Failed to send Ether");
    }

    /// @dev Allows the owner to withdraw any erc20 tokens sent to this contract
    /// @param token The ERC20 token to withdraw
    function withdrawTokens(IERC20 token) public onlyOwner {
      uint256 balance = token.balanceOf(address(this));
      token.transfer(msg.sender, balance);
    }

    /// ~~~~~~~~~~~~~~~~~~~~~~ CUSTOM LOGIC ~~~~~~~~~~~~~~~~~~~~~~~ ///

    /// @dev Support for EIP 2981 Interface by overriding erc165 supportsInterface
    /// @param interfaceId The 4 byte interface id to check against
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
      return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
        interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    /// @notice Converts a uint256 into a string
    /// @param value The value to convert to a string
    function toString(uint256 value) public pure returns (string memory) {
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
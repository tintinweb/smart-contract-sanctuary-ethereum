// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 * CloudNouns.sol
 *
 * Author: Badu Blanc // badublanc.eth // twitter: badublanc
 * Created: May 21th, 2022
 * Acknowledgements: NounsDAO, Nouns Prop House, Austin Griffith, Buildspace
 * More info at cloudnouns.com/nft
 *
 * Mint Price:
 *   - Mint 1 token per txn for free
 *   - Bulk mint @ 0.01 ETH per token
 *   - 25% of proceeds sent to NounsDAO
 *
 * ███    ██  ██████  ██    ██ ███    ██ ██ ███████ ██   ██
 * ████   ██ ██    ██ ██    ██ ████   ██ ██ ██      ██   ██
 * ██ ██  ██ ██    ██ ██    ██ ██ ██  ██ ██ ███████ ███████
 * ██  ██ ██ ██    ██ ██    ██ ██  ██ ██ ██      ██ ██   ██
 * ██   ████  ██████   ██████  ██   ████ ██ ███████ ██   ██
 *
 */

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./Utils.sol";

error HoldsNoTokens();
error MintingPaused();
error TokenDoesNotExist(uint256 tokenId);
error WrongEtherAmount();

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}

interface IERC2981 {
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}

contract CloudNouns is ERC721, IERC2981, Ownableish, ReentrancyGuard {
  using Stringish for uint256;

  string public baseURI = "https://api.cloudnouns.com/nft/tokens/";
  bool public isPaused = false;
  uint256 public totalSupply;
  uint256 public PRICE_PER_MINT = 0.01 ether;
  uint16 public ROYALTY_BPS = 500;

  address NounsDAOAddress = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

  event NewNoun(uint256 _id, address _owner, uint256 _ts);
  event NounsDAOAddressUpdated(address _newAddress);

  constructor() payable ERC721("Cloud Nouns", "CLOUDNOUN") {}

  modifier whenNotPaused() {
    if (isPaused) revert MintingPaused();
    _;
  }

  function _mintNoun(address _address) private {
    uint256 _id = ++totalSupply;
    _mint(_address, _id);
    emit NewNoun(_id, _address, block.timestamp);
  }

  function mintOne(address _address) external whenNotPaused nonReentrant {
    _mintNoun(_address);
  }

  function bulkMint(address[] calldata _addresses)
    external
    payable
    whenNotPaused
    nonReentrant
  {
    uint256 amount = _addresses.length;
    if (msg.value != amount * PRICE_PER_MINT) {
      revert WrongEtherAmount();
    }

    for (uint16 i = 0; i < amount; i++) {
      _mintNoun(_addresses[i]);
    }
  }

  function _setMintPrice(uint256 _price) external onlyOwner {
    PRICE_PER_MINT = _price;
  }

  function getTokensByOwner(address _address)
    external
    view
    returns (uint256[] memory)
  {
    uint256 balance = this.balanceOf(_address);
    if (balance == 0) revert HoldsNoTokens();

    uint256 index = 0;
    uint256[] memory tokens = new uint256[](balance);
    for (uint256 i = 1; i <= totalSupply; i++) {
      if (this.ownerOf(i) == _address) {
        tokens[index] = i;
        index++;
      }
    }
    return tokens;
  }

  function togglePause() external onlyOwner {
    isPaused = !isPaused;
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setRoyaltyBPS(uint16 _bps) external onlyOwner {
    ROYALTY_BPS = _bps;
  }

  function updateNounsDaoAddress(address _address) external onlyOwner {
    NounsDAOAddress = _address;
    emit NounsDAOAddressUpdated(_address);
  }

  function withdrawETH() external {
    uint256 balance = address(this).balance;
    uint256 daoShare = balance / 4;

    SafeTransferLib.safeTransferETH(NounsDAOAddress, daoShare);
    SafeTransferLib.safeTransferETH(_owner, balance - daoShare);
  }

  function withdrawERC20(address _contract) external {
    uint256 balance = IERC20(_contract).balanceOf(address(this));
    uint256 daoShare = balance / 4;

    SafeTransferLib.safeTransfer(_contract, NounsDAOAddress, daoShare);
    SafeTransferLib.safeTransfer(_contract, _owner, balance - daoShare);
  }

  function withdrawERC721(address _contract, uint256 _token) external {
    ERC721(_contract).safeTransferFrom(address(this), _owner, _token);
  }

  function tokenURI(uint256 _id) public view override returns (string memory) {
    if (ownerOf[_id] == address(0)) revert TokenDoesNotExist(_id);
    return string(abi.encodePacked(baseURI, _id.toString()));
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    receiver = address(this);
    royaltyAmount = (_salePrice * ROYALTY_BPS) / 10000;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(ERC721, Ownableish)
    returns (bool)
  {
    return
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
  uint256 private locked = 1;

  modifier nonReentrant() {
    require(locked == 1, "REENTRANCY");
    locked = 2;
    _;
    locked = 1;
  }
}

// Modified from OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
library Stringish {
  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
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

// Modified from OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
abstract contract Ownableish {
  error NotOwner();

  address internal _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _owner = msg.sender;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    if (msg.sender != _owner) revert NotOwner();
    _;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    _owner = _newOwner;
  }

  function renounceOwnership() public onlyOwner {
    _owner = address(0);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
  }
}

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
library SafeTransferLib {
  error ETHTransferFailed();
  error TransferFailed();

  function safeTransferETH(address to, uint256 amount) internal {
    bool success;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), to, amount, 0, 0, 0, 0)
    }

    if (!success) revert ETHTransferFailed();
  }

  function safeTransfer(
    address token,
    address to,
    uint256 amount
  ) internal {
    bool success;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata into memory, beginning with the function selector.
      mstore(
        freeMemoryPointer,
        0xa9059cbb00000000000000000000000000000000000000000000000000000000
      )
      mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
      mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

      success := and(
        // Set success to whether the call reverted, if not we check it either
        // returned exactly 1 (can't just be non-zero data), or had no return data.
        or(
          and(eq(mload(0), 1), gt(returndatasize(), 31)),
          iszero(returndatasize())
        ),
        // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
        // Counterintuitively, this call must be positioned second to the or() call in the
        // surrounding and() call or else returndatasize() will be zero during the computation.
        call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
      )
    }

    if (!success) revert TransferFailed();
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
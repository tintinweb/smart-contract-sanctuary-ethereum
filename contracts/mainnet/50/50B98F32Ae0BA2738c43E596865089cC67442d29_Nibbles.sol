// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Nibbles is IERC1155 {
  address admin;
  bool initialized;

  mapping(address => bool) public auth;

  /***********************************|
    |        Variables and Events       |
    |__________________________________*/

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  mapping(address => mapping(uint256 => uint256)) internal balances;
  mapping(address => mapping(address => bool)) internal operators;
  string public ratsLair;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  function name() external pure returns (string memory) {
    return "Nibbles";
  }

  function symbol() external pure returns (string memory) {
    return "NIBBLE";
  }

  function initialize() public {
    require(!initialized, "Already initialized");
    admin = msg.sender;
    auth[msg.sender] = true;
    initialized = true;
    ratsLair = "https://api.ratrace.wtf/api/nibbles/";
  }  

  function mint(uint256 quantity, uint256 tokenId) external {
    onlyOwner();
    _mint(msg.sender, tokenId, quantity);
  }

  function freebie(address ratKeeper, uint256 _nibble) external {
    require(auth[msg.sender], "FORBIDDEN TO MINT");

    uint256 rand = (uint16(_randomize(_rand(), "he", _nibble)) % 100);
    uint256 nibble = (rand < 50) ? 0 : (rand > 50 && rand < 75)
      ? 1
      : (rand > 75 && rand < 95)
      ? 2
      : 3;
    if (nibble > 0) {
      _mint(ratKeeper, nibble, 1);
    }
  }

  function reserve(uint256 quantity, uint256 tokenId) external {
    onlyOwner();
    _mint(msg.sender, tokenId, quantity);
  }

  function burn(
    address from,
    uint256 id,
    uint256 value
  ) external {
    require(auth[msg.sender], "FORBIDDEN TO BURN");
    _burn(from, id, value);
  }

  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    balances[_to][_id] += _amount;
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);
  }

  function _burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) internal {
    balances[_from][_id] -= _amount;
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  //ADMIN

  function onlyOwner() internal view {
    require(admin == msg.sender);
  }

  function onlyOperator() internal view {
    require(auth[msg.sender] == true, "not Authorized");
  }

  function isPlayer() internal {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }
    require((msg.sender == tx.origin && size == 0));
  }

  function setAuth(address[] calldata adds_, bool status) public {
    onlyOwner();

    for (uint256 index = 0; index < adds_.length; index++) {
      auth[adds_[index]] = status;
    }
  }

  function getTokenURI(uint256 _id) public view returns (string memory) {
    return string(abi.encodePacked(ratsLair, Strings.toString(_id)));
  }

  function setRatsLair(string memory _ratsLair) public {
    onlyOwner();
    ratsLair = _ratsLair;
  }

  /***********************************|
    |     Randomness Functions          |
    |__________________________________*/

  function _randomize(
    uint256 ran,
    string memory dom,
    uint256 ness
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran, dom, ness)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            msg.sender,
            block.difficulty,
            block.timestamp,
            block.basefee
          )
        )
      );
  }

  /***********************************|
    |     Public Transfer Functions     |
    |__________________________________*/

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) public override {
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155#safeTransferFrom: INVALID_OPERATOR"
    );
    require(_to != address(0), "ERC1155#safeTransferFrom: INVALID_RECIPIENT");

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) public override {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR"
    );
    require(
      _to != address(0),
      "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT"
    );

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  /***********************************|
    |    Internal Transfer Functions    |
    |__________________________________*/

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    // Update balances
    balances[_from][_id] -= _amount;
    balances[_to][_id] += _amount;

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Check if recipient is contract
    if (_to.code.length != 0) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{
        gas: _gasLimit
      }(msg.sender, _from, _id, _amount, _data);
      require(
        retval == ERC1155_RECEIVED_VALUE,
        "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  function _safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    require(
      _ids.length == _amounts.length,
      "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
    );

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      balances[_from][_ids[i]] -= _amounts[i];
      balances[_to][_ids[i]] += _amounts[i];
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Pass data if recipient is contract
    if (_to.code.length != 0) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{
        gas: _gasLimit
      }(msg.sender, _from, _ids, _amounts, _data);
      require(
        retval == ERC1155_BATCH_RECEIVED_VALUE,
        "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  /***********************************|
    |         Operator Functions        |
    |__________________________________*/

  function setApprovalForAll(address _operator, bool _approved)
    external
    override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }

  /***********************************|
    |         Balance Functions         |
    |__________________________________*/

  function balanceOf(address _owner, uint256 _id)
    public
    view
    override
    returns (uint256)
  {
    return balances[_owner][_id];
  }

  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public
    view
    override
    returns (uint256[] memory)
  {
    require(
      _owners.length == _ids.length,
      "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH"
    );

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }

  function uri(uint256 _id) public view returns (string memory) {
    return getTokenURI(_id);
  }

  function owner() external view returns (address own_) {
    own_ = admin;
  }

  /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/

  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return _interfaceID == this.supportsInterface.selector;
  }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERNAL ELVES TEAM.
library Base64 {
  string internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IERC1155Lite {
    function burn(address from,uint256 id, uint256 value) external;
    function freebie(address ratKeeper, uint256 nibble) external;
    function balanceOf(address _owner, uint256 _id) external returns (uint256); 
}

 
//1155
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
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
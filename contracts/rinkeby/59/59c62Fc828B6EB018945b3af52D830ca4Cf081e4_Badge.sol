// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Soulbound(string _method);

/// @notice A minimalist soulbound ERC-721 implementaion with hierarchical
///         allow-lists and token delegation.
/// @author MOONSHOT COLLECTIVE (https://github.com/moonshotcollective)
contract Badge is ERC721, Ownable {
  event OPsAdded(address indexed _sender, address[] indexed _op);
  event OPCOsAdded(address indexed _op, uint256 indexed _lastCursor, address[] indexed _opco);
  event CitizensAdded(address indexed _opco, uint256 indexed _lastCursor, address[] indexed _citizen);
  event CitizenRemoved(address indexed _opco, address indexed _removed);
  event Minted(address indexed _minter, address indexed _opco);
  event Burned(address indexed _burner);

  /*///////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

  modifier onlyOP() {
    require(isOP(msg.sender), "Error: Sender Not OP");
    _;
  }

  modifier onlyOPCO() {
    require(isOPCO(msg.sender), "Error: Sender Not OPCO");
    _;
  }

  modifier onlyCitizen() {
    require(isCitizen(msg.sender), "Error: Sender Not Citizen");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  struct OP {
    address op;
  }

  struct OPCO {
    address co;
    address[] citizens;
    uint256 supply;
    uint256 minted;
  }

  struct Citizen {
    address citizen;
    address opco;
    bool minted;
    address delegate;
    uint256 delegations;
  }

  uint256 public CitizenCount;
  uint256 public OPCOCount;

  string private baseURI;
  uint256 private totalSupply;

  OP[] internal OPs;
  OPCO[] internal OPCOs;
  Citizen[] internal Citizens;

  mapping(address => uint256) internal OPIndexMap;
  mapping(address => uint256) internal OPCOIndexMap;
  mapping(address => uint256) internal CitizenIndexMap;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(
    address[] memory _ops,
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) payable ERC721(_name, _symbol) {
    baseURI = _baseURI;
    for (uint256 i = 0; i < _ops.length; i++) {
      _newOP(_ops[i]);
    }
  }

  /*///////////////////////////////////////////////////////////////
                              OP  LOGIC
    //////////////////////////////////////////////////////////////*/

  function addOPs(address[] memory _adrs) external onlyOP {
    for (uint256 i = 0; i < _adrs.length; i++) {
      _newOP(_adrs[i]);
    }
    emit OPsAdded(msg.sender, _adrs);
  }

  function addOPCOs(address[] memory _adrs, uint256[] memory _supplies)
    external
    onlyOP
  {
    for (uint256 i = 0; i < _adrs.length; i++) {
      _newOPCO(_adrs[i], _supplies[i]);
    }
    emit OPCOsAdded(msg.sender, OPCOCount, _adrs);
  }

  // TODO: Remove OPCO & OP Methods

  /*///////////////////////////////////////////////////////////////
                              OPCO  LOGIC
    //////////////////////////////////////////////////////////////*/

  function addCitizens(address[] memory _adrs) external onlyOPCO {
    require(
      OPCOs[OPCOIndexMap[msg.sender]].citizens.length + _adrs.length <=
        OPCOs[OPCOIndexMap[msg.sender]].supply,
      "Error: Exceeds OPCO Supply."
    );
    for (uint256 i = 0; i < _adrs.length; i++) {
      _newCitizen(_adrs[i]);
    }
    emit CitizensAdded(msg.sender, CitizenCount, _adrs);
  }

  function removeCitizen(address _adr) external onlyOPCO {
    // ADDME: Check if OPCO removing the citizen is the citizen's opco
    // Remove citizen address from OPCO data storage
    _deleteOPCOCitizen(msg.sender, _adr);
    // Remove Citizen data storage
    _deleteCitizen(_adr);
    emit CitizenRemoved(msg.sender, _adr);
  }

  /*///////////////////////////////////////////////////////////////
                            CITIZEN LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Mint
  /// @dev Mints the soulbound ERC721 token.
  function mint() external onlyCitizen {
    require(balanceOf(msg.sender) < 1, "Error: Already Minted."); 
    _mint(msg.sender, totalSupply++);
    Citizens[CitizenIndexMap[msg.sender]].minted = true;
    OPCOs[OPCOIndexMap[Citizens[CitizenIndexMap[msg.sender]].opco]].minted++;
    emit Minted(msg.sender, Citizens[CitizenIndexMap[msg.sender]].opco);
  }

  /// @notice Burn
  /// @dev Burns the soulbound ERC721.
  /// @param _id The token URI.
  function burn(uint256 _id) external onlyCitizen {
    _burn(_id);
    _deleteCitizen(msg.sender);
    _deleteOPCOCitizen(Citizens[CitizenIndexMap[msg.sender]].opco, msg.sender);
    emit Burned(msg.sender);
  }

  function delegate(address _adr) external onlyCitizen {
    // ADDME: Check if _adr is a citizen
    Citizens[CitizenIndexMap[msg.sender]].delegate = _adr;
    Citizens[CitizenIndexMap[_adr]].delegations++;
  }

  function undelegate(address _adr) external onlyCitizen {
    Citizens[CitizenIndexMap[msg.sender]].delegate = address(0);
    Citizens[CitizenIndexMap[_adr]].delegations--;
  }

  /*///////////////////////////////////////////////////////////////
                            HELPER LOGIC
  //////////////////////////////////////////////////////////////*/

  function isOP(address _adr) public view returns (bool) {
    return OPs[OPIndexMap[_adr]].op == _adr;
  }

  function isOPCO(address _adr) public view returns (bool) {
    return OPCOs[OPCOIndexMap[_adr]].co == _adr;
  }

  function isCitizen(address _adr) public view returns (bool) {
    return Citizens[CitizenIndexMap[_adr]].citizen == _adr;
  }

  function getOPs() external view returns (OP[] memory) {
    return OPs;
  }

  function getOP(address _adr) external view returns (OP memory) {
    return OPs[OPIndexMap[_adr]];
  }

  function getOPCOs(uint256 cursor, uint256 count)
    public
    view
    returns (OPCO[] memory, uint256 newCursor)
  {
    uint256 length = count;
    if (length > OPCOs.length - cursor) {
      length = OPCOs.length - cursor;
    }
    OPCO[] memory values = new OPCO[](length);
    for (uint256 i = 0; i < length; i++) {
      values[i] = OPCOs[cursor + i];
    }
    return (values, count + length);
  }

  function getOPCO(address _adr) public view returns (OPCO memory) {
    return OPCOs[OPCOIndexMap[_adr]];
  }

  function getCitizens(uint256 cursor, uint256 count)
    public
    view
    returns (Citizen[] memory, uint256 newCursor)
  {
    uint256 length = count;
    if (length > Citizens.length - cursor) {
      length = Citizens.length - cursor;
    }
    Citizen[] memory values = new Citizen[](length);
    for (uint256 i = 0; i < length; i++) {
      values[i] = Citizens[cursor + i];
    }
    return (values, count + length);
  }

  function getCitizen(address _adr) public view returns (Citizen memory) {
    return Citizens[CitizenIndexMap[_adr]];
  }

  /*///////////////////////////////////////////////////////////////
                            CONTRACT LOGIC
    //////////////////////////////////////////////////////////////*/

  function _newOP(address _adr) private {
    // ADDME: Role Check! _adr should not have ANY other role
    OP memory op = OP({op: _adr});
    OPs.push(op);
    OPIndexMap[_adr] = OPs.length - 1;
  }

  function _newOPCO(address _adr, uint256 _supply) private {
    // ADDME: Role Check! _adr should not have ANY other role
    address[] memory _citizens;
    OPCO memory opco = OPCO({
      co: _adr,
      citizens: _citizens,
      supply: _supply,
      minted: 0
    });
    OPCOs.push(opco);
    OPCOIndexMap[_adr] = OPCOs.length - 1;
    OPCOCount++;
  }

  function _newCitizen(address _adr) private {
    // ADDME: Role Check! _adr should not have ANY other role
    Citizen memory citizen = Citizen({
      citizen: _adr,
      opco: msg.sender,
      minted: false,
      delegate: address(0),
      delegations: 0
    });
    Citizens.push(citizen);
    CitizenIndexMap[_adr] = Citizens.length - 1;
    OPCOs[OPCOIndexMap[msg.sender]].citizens.push(_adr);
    CitizenCount++;
  }

  function _deleteCitizen(address _adr) private {
    // ADDME: check if the index map is maxint (i.e. already deleted)
    uint256 _delIndex = CitizenIndexMap[_adr];
    // move all elements to the left, starting from the index + 1
    for (uint256 i = _delIndex; i < Citizens.length - 1; i++) {
      Citizens[i] = Citizens[i + 1];
    }
    Citizens.pop(); // delete the last item
    CitizenIndexMap[_adr] = 2**256 - 1; // set the index map to MAXINT
    CitizenCount--;
  }

  function _deleteOPCOCitizen(address _opco, address _adr) private {
    uint256 _opcoIndex = OPCOIndexMap[_opco];
    uint256 _delIndex;
    for (uint256 i = 0; i < OPCOs[_opcoIndex].citizens.length; i++) {
      if (OPCOs[_opcoIndex].citizens[i] == _adr) {
        _delIndex = i;
        break;
      }
      // TODO: add revert
    }
    // move all elements to the left, starting from index + 1
    for (
      uint256 i = _delIndex;
      i < OPCOs[_opcoIndex].citizens.length - 1;
      i++
    ) {
      OPCOs[OPCOIndexMap[_opco]].citizens[i] = OPCOs[_opcoIndex].citizens[
        i + 1
      ];
    }
    OPCOs[OPCOIndexMap[_opco]].citizens.pop();
  }

  // TODO: delete opco, which deletes the citizen data too, onlyOP
  // function _deleteOPCO(address _adr) internal onlyOP {}

  // TODO: delete OP
  // function _deleteOP(address _adr) internal onlyOP {}

  // TODO: updateBaseURI

  /// @notice Token URI
  /// @dev Generate a token URI.
  /// @param _id The token URI.
  function tokenURI(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, _id));
  }

  /// @notice Transfer ERC721
  /// @dev Override the ERC721 transferFrom method to revert
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override {
    // Make it ~*~ Soulbound ~*~
    revert Soulbound("transferFrom(address, address, uint256)");
  }

  /// @notice Approve ERC721
  /// @dev Override the ERC721 Approve method to revert
  function approve(address, uint256) public pure override {
    revert Soulbound("approve(address, uint256)");
  }

  /// @notice setApprovalForAll ERC721
  /// @dev Override the ERC721 setApprovalForAll method to revert
  function setApprovalForAll(address, bool) public pure override {
    revert Soulbound("setApprovalForAll(address, uint256)");
  }

  /// @notice Withdraw
  /// @dev Withdraw the contract ETH balance
  function withdraw() external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

  // https://eips.ethereum.org/EIPS/eip-165#simple-summary
  function supportsInterface(bytes4 _interfaceId)
    public
    pure
    override(ERC721)
    returns (bool)
  {
    return
      _interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      _interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      _interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      _interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
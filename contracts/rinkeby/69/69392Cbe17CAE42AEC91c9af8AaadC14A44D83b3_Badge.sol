// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DoesNotExist();
error Soulbound();
error AlreadyClaimed();
error NotCitizen();
error OpCoExists();
error CitizenExists();
error InvalidDelegation();
error InvalidBurn();
error InvalidSupply();
error InvalidOpCo();

/// @notice A minimalist soulbound ERC-721 implementaion with hierarchical
///         allow-lists and token delegation.
/// @author MOONSHOT COLLECTIVE (https://github.com/moonshotcollective)
contract Badge is ERC721, Ownable {

  /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

  event UpdatedOP(address indexed sender);
  event Burned(address indexed sender, uint256 id);
  event Delegated(address indexed from, address to);
  event SetOP(address indexed sender, address input);
  event Undelegated(address indexed by, address from);
  event Minted(address indexed citizen, address opco);
  event UpdatedOPCo(address indexed sender, address opco);
  event SetCitizens(address indexed sender, address[] citizens);
  event NewOPCo(address indexed sender, address op, uint256 supply);
  event UpdatedCitizen(address indexed sender, address from, address to);

  /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  struct OpCo {
    uint256 supply;
    uint256 minted;
    uint256 allocated;
    address[] citizens;
  }

  string public baseURI;
  uint256 public totalSupply;

  address[] internal opAdrs;
  address[] internal opCoAdrs;
  address[] internal mintedAdrs;

  mapping(address => OpCo) internal opCoMap;
  mapping(address => bool) internal isOpMap;
  mapping(address => bool) internal isOpCoMap;
  mapping(address => bool) internal isCitizenMap;
  mapping(address => address) internal citizenOpCoMap;
  mapping(address => address) internal delegatedToMap;
  mapping(address => uint256) internal delegationsMap;
  mapping(address => uint256) internal opCoCitizenIndex;

  /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(
    address[] memory _op,
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) payable ERC721(_name, _symbol) {
    baseURI = _baseURI;
    for (uint256 i = 0; i < _op.length; ++i) {
      isOpMap[_op[i]] = true;
      opAdrs.push(_op[i]);
    }
  }

  /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

  modifier onlyOp() {
    require(isOp(msg.sender), "Not Op");
    _;
  }

  modifier onlyOpCo() {
    require(isOpCo(msg.sender), "Not OpCo");
    _;
  }

  modifier onlyCitizen() {
    require(isCitizen(msg.sender), "Not Citizen");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                                OP  LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Set OP
  /// @dev Set OP Controllers. OP Controllers have access to OnlyOp methods.
  /// @param _opAdr Address array of OP controllers
  function setOp(address _opAdr) public onlyOp {
    isOpMap[_opAdr] = true;
    opAdrs.push(_opAdr);
    emit SetOP(msg.sender, _opAdr);
  }

  /// @notice Set Base URI
  /// @dev Set ERC721 Base URI for the ERC721 token.
  /// @param _baseURI Base URI string
  function setBaseURI(string memory _baseURI) public onlyOp {
    baseURI = _baseURI;
  }

  /// @notice Set OP Co's
  /// @dev Set the OPCo's, which allow access to OnlyOpCo restricted methods.
  /// @param _opCoAdrs Address array of OP Co Addresses to set
  /// @param _opCoSupplies Integer array of token supply for each of _opCoAdrs
  function setOpCos(address[] memory _opCoAdrs, uint256[] memory _opCoSupplies)
    public
    onlyOp
  {
    for (uint256 i = 0; i < _opCoAdrs.length; ++i) {
      if (isOpCo(_opCoAdrs[i])) revert OpCoExists();
      _newOpCo(_opCoAdrs[i], _opCoSupplies[i]);
      isOpCoMap[_opCoAdrs[i]] = true;
    }
  }

  /// @notice New OP Co
  /// @dev Create a New OP Co and instantiate N citizens with address(0)
  /// @param _opCoAdr Address of OP Co to update
  /// @param _opCoSupply Integer supply of mintable tokens
  function _newOpCo(address _opCoAdr, uint256 _opCoSupply) internal {
    address[] memory citizens = new address[](_opCoSupply);
    opCoMap[_opCoAdr] = OpCo({
      supply: _opCoSupply,
      minted: 0,
      allocated: 0,
      citizens: citizens
    });
    opCoAdrs.push(_opCoAdr);
    emit NewOPCo(msg.sender, _opCoAdr, _opCoSupply);
  }

  /// @notice Update OP Co token supply
  /// @dev Update the ERC721 token mint supply for an OP Co.
  /// @param _opCoAdr Address of OPCo to update
  /// @param _opCoSupply Integer supply of mintable tokens
  function updateOpCoSupply(address _opCoAdr, uint256 _opCoSupply)
    public
    onlyOp
  {
    if (_opCoSupply <= opCoMap[_opCoAdr].minted) {
      opCoMap[_opCoAdr].supply = opCoMap[_opCoAdr].minted;
    } else {
      opCoMap[_opCoAdr].supply = _opCoSupply;
    }
    emit UpdatedOPCo(msg.sender, _opCoAdr);
  }
  
  /*///////////////////////////////////////////////////////////////
                              OPCO  LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Set Citizens
  /// @dev Set Citizens within and the senders OP Co supply limit
  /// @param _citizens Address array of citizens to set
  function setCitizens(address[] memory _citizens) public onlyOpCo {
    require(
      opCoMap[msg.sender].supply - opCoMap[msg.sender].allocated >=
        _citizens.length,
      "Citizen Count Exceeds Supply"
    );
    for (uint256 i = 0; i < _citizens.length; ++i) {
      if (isCitizen(_citizens[i])) revert CitizenExists();
      isCitizenMap[_citizens[i]] = true;
      opCoMap[msg.sender].citizens[i] = _citizens[i];
      citizenOpCoMap[_citizens[i]] = msg.sender;
      uint256 pos = opCoMap[msg.sender].allocated;
      opCoMap[msg.sender].citizens[pos] = _citizens[i];
      opCoCitizenIndex[_citizens[i]] = pos;
      opCoMap[msg.sender].allocated++;
    }
    emit SetCitizens(msg.sender, _citizens);
  }

  /// @notice Update Citizen
  /// @dev Replace citizen1 with citizen2
  /// @param _citizen Position of _citizen1 in the citizens array
  /// @param _update Position of _citizen1 in the citizens array
  function updateCitizen(address _citizen, address _update) public onlyOpCo {
    if (!isCitizen(_citizen)) revert NotCitizen();
    if (balanceOf(_citizen) > 0) revert AlreadyClaimed();
    if (isCitizen(_update)) revert CitizenExists();
    if (citizenOpCoMap[_citizen] != msg.sender) revert InvalidOpCo();
    uint256 pos = opCoCitizenIndex[_citizen];
    citizenOpCoMap[_update] = msg.sender;
    isCitizenMap[_citizen] = false;
    isCitizenMap[_update] = true;
    opCoMap[msg.sender].citizens[pos] = _update;
    emit UpdatedCitizen(msg.sender, _citizen, _update);
  }

  /*///////////////////////////////////////////////////////////////
                              BADGE LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Mint
  /// @dev Mints the soulbound ERC721 token.
  function mint() external payable onlyCitizen {
    if (msg.sender == address(0)) revert DoesNotExist();
    if (balanceOf(msg.sender) > 0) revert AlreadyClaimed();
    address _citizenOpCo = citizenOpCoMap[msg.sender];
    if (opCoMap[_citizenOpCo].minted >= opCoMap[_citizenOpCo].supply)
      revert InvalidSupply();
    opCoMap[_citizenOpCo].minted++;
    _mint(msg.sender, totalSupply++);
    mintedAdrs.push(msg.sender);
    delegationsMap[msg.sender] = 1;
    delegatedToMap[msg.sender] = msg.sender;
    emit Minted(msg.sender, citizenOpCoMap[msg.sender]);
  }

  /// @notice Burn
  /// @dev Burns the soulbound ERC721.
  /// @param _id The token URI.
  function burn(uint256 _id) external onlyCitizen {
    if (balanceOf(msg.sender) != 1 || ownerOf(_id) != msg.sender)
      revert InvalidBurn();
    // TODO: What should happen on burn?
    //   _burn(_id);
    //
    emit Burned(msg.sender, _id);
  }

  /// @notice Delegate token
  /// @dev Delegate a singular token (without transfer) to another holder.
  /// @param _to The address the sender is delegating to.
  function delegate(address _to) external onlyCitizen {
    if (
      balanceOf(msg.sender) != 1 ||
      isDelegated(msg.sender) ||
      balanceOf(_to) == 0
    ) revert InvalidDelegation();
    delegatedToMap[msg.sender] = _to;
    delegationsMap[msg.sender] = 0;
    delegationsMap[_to] += 1;
    emit Delegated(msg.sender, _to);
  }

  /// @notice Un-Delegate token
  /// @dev Un-Delegate a singular token (without transfer) from an address.
  /// @param _from The address the sender is un-delegating from.
  function undelegate(address _from) external onlyCitizen {
    if (
      balanceOf(msg.sender) != 1 ||
      !isDelegated(msg.sender) ||
      delegatedToMap[msg.sender] != _from
    ) revert InvalidDelegation();
    delegatedToMap[msg.sender] = msg.sender;
    delegationsMap[msg.sender] = 1;
    delegationsMap[_from] -= 1;
    emit Undelegated(msg.sender, _from);
  }

  /// @notice Token URI
  /// @dev Generate a token URI.
  /// @param _id The token URI.
  function tokenURI(uint256 _id) public view override returns (string memory) {
    if (msg.sender == address(0)) revert DoesNotExist();
    return string(abi.encodePacked(baseURI, _id));
  }

  /*///////////////////////////////////////////////////////////////
                              HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Is OP
  /// @dev Boolean check if address is an OP address
  /// @param _adr The address to check
  function isOp(address _adr) public view returns (bool) {
    return isOpMap[_adr];
  }

  /// @notice Is OP Co
  /// @dev Boolean check if address is an OP Co address
  /// @param _adr The address to check
  function isOpCo(address _adr) public view returns (bool) {
    return isOpCoMap[_adr];
  }

  /// @notice Is Citizen
  /// @dev Boolean check if address is a Citizen address
  /// @param _adr The address to check
  function isCitizen(address _adr) public view returns (bool) {
    return isCitizenMap[_adr];
  }

  /// @notice Is Delegated
  /// @dev Boolean check if address has delegated their token
  /// @param _adr The address to check
  function isDelegated(address _adr) public view returns (bool) {
    return delegatedToMap[_adr] != _adr;
  }

  /// @notice Get Delegated
  /// @dev Get the delegate address from the input address
  /// @param _adr Input address
  function getDelegatedTo(address _adr) public view returns (address) {
    return delegatedToMap[_adr];
  }

  /// @notice Get OP's
  /// @dev Get the OP addresses
  function getOpAddresses() public view returns (address[] memory) {
    return opAdrs;
  }

  /// @notice Get OP Co's
  /// @dev Get the OP Co addresses
  function getOpCoAddresses() public view returns (address[] memory) {
    return opCoAdrs;
  }

  /// @notice Get Minters
  /// @dev Get the addresses of the minted tokens
  function getMintedAddresses() public view returns (address[] memory) {
    return mintedAdrs;
  }

  /// @notice Get OP Co Supply
  /// @dev Get the token supply of an Op Co
  /// @param _adr Input address
  function getOpCoSupply(address _adr) public view returns (uint256) {
    return opCoMap[_adr].supply;
  }

  /// @notice Get OP Co Allocation
  /// @dev Get the token allocation of an Op Co
  /// @param _adr Input address
  function getOpCoAllocated(address _adr) public view returns (uint256) {
    return opCoMap[_adr].allocated;
  }

  /// @notice Get OP Co Citizens
  /// @dev Get the citizens of an OP Co
  /// @param _opco Op Co Address
  function getOpCoCitizens(address _opco)
    public
    view
    returns (address[] memory)
  {
    return opCoMap[_opco].citizens;
  }

  /// @notice Get OP Co Minted
  /// @dev Get the number of currently minted OP Co tokens
  /// @param _opco Op Co Address
  function getOpCoMinted(address _opco) public view returns (uint256) {
    return opCoMap[_opco].minted;
  }

  /// @notice Get Citizen Delegations
  /// @dev Get the number of delegations the citizen has
  /// @param _citizen Citizen Address
  function getCitizenDelegations(address _citizen)
    public
    view
    returns (uint256)
  {
    return delegationsMap[_citizen];
  }

  /// @notice Is an Op CO citizen
  /// @dev Boolean check if a citizen is member of an OP Co
  /// @param _opco OP Co Address
  /// @param _citizen Citizen Address
  function isOpCoCitizen(address _opco, address _citizen)
    public
    view
    returns (bool)
  {
    for (uint256 i = 0; i < opCoMap[_opco].citizens.length; ++i) {
      if (opCoMap[_opco].citizens[i] == _citizen) {
        return true;
      }
    }
    return false;
  }

  /// @notice Get Citizenship
  /// @dev Get the OP Co Address the citizen is part of
  /// @param _citizen Citizen address
  function getCitizenOpCo(address _citizen) public view returns (address) {
    return citizenOpCoMap[_citizen];
  }

  /*///////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Transfer ERC721
  /// @dev Override the ERC721 transferFrom method to revert
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override {
    // Make it ~*~ Soulbound ~*~
    revert Soulbound();
  }

  /// @notice Approve ERC721
  /// @dev Override the ERC721 Approve method to revert

  function approve(address spender, uint256 id) public pure override {
    // Make it ~*~ Soulbound ~*~
    revert Soulbound();
  }

  /// @notice setApprovalForAll ERC721
  /// @dev Override the ERC721 setApprovalForAll method to revert

  function setApprovalForAll(address operator, bool approved) public pure override {
    // Make it ~*~ Soulbound ~*~
    revert Soulbound();
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
      _interfaceId == 0x01ffc9a7;   // ERC165 Interface ID for ERC721Metadata
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
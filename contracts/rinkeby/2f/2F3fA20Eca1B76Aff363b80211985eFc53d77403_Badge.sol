// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error InvalidMinter();
error DoesNotExist();
error Soulbound();
error AlreadyClaimed();
error NotOpCo();
error NotOp();
error NotCitizen();
error OpCoExists();
error CitizenExists();
error InvalidBalance();
error AlreadyDelegated();
error NotDelegated();
error InvalidDelegation();
error InvalidBurn();
error InvalidSupply();

/// @notice A minimalist soulbound ERC-721 implementaion with hierarchical
///         whitelisting and token delegation.
/// @author MOONSHOT COLLECTIVE (https://github.com/moonshotcollective)
contract Badge is ERC721, Ownable {

  /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

  // NFT Minted by citizen belonging to opco
  event Minted(address indexed citizen, address indexed opco);
  // Votes delegated from citizen A to Citizen B
  event Delegated(address indexed from, address indexed to);
  // Votes undelegated by citizen A from citizen B
  event Undelegated(address indexed by, address indexed from);
  // OPCOs updated
  event UpdatedOPCOs();
  // Citizens updated
  event UpdatedCitizens();

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

  function setOp(address _opAdrs) public onlyOp {
    isOpMap[_opAdrs] = true;
    opAdrs.push(_opAdrs);
  }

  function setBaseURI(string memory _baseURI) public onlyOp {
    baseURI = _baseURI;
  }

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

  function _newOpCo(address _opCoAdr, uint256 _opCoSupply) internal {
    address[] memory citizens = new address[](_opCoSupply);
    opCoMap[_opCoAdr] = OpCo({
      supply: _opCoSupply,
      minted: 0,
      allocated: 0,
      citizens: citizens
    });
    opCoAdrs.push(_opCoAdr);
  }

  function updateOpCoSupply(address _opCoAdr, uint256 _opCoSupply)
    public
    onlyOp
  {
    if (_opCoSupply <= opCoMap[_opCoAdr].minted) {
      opCoMap[_opCoAdr].supply = opCoMap[_opCoAdr].minted;
    } else {
      opCoMap[_opCoAdr].supply = _opCoSupply;
    }
  }

  /*///////////////////////////////////////////////////////////////
                              OPCO  LOGIC
    //////////////////////////////////////////////////////////////*/

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
  }

  /// @dev Replace citizen1 with citizen2
  /// @param _citizen Position of _citizen1 in the citizens array
  /// @param _update Position of _citizen1 in the citizens array
  function updateCitizen(address _citizen, address _update) public onlyOpCo {
    if (!isCitizen(_citizen)) revert NotCitizen();
    if (balanceOf[_citizen] > 0) revert AlreadyClaimed();
    if (isCitizen(_update)) revert CitizenExists();
    uint256 pos = opCoCitizenIndex[_citizen];
    citizenOpCoMap[_update] = msg.sender;
    isCitizenMap[_citizen] = false;
    isCitizenMap[_update] = true;
    opCoMap[msg.sender].citizens[pos] = _update;
  }

  /*///////////////////////////////////////////////////////////////
                              BADGE LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Mint
  /// @dev Mints the soulbound ERC721 token.
  function mint() external payable onlyCitizen {
    if (msg.sender == address(0)) revert DoesNotExist();
    if (balanceOf[msg.sender] > 0) revert AlreadyClaimed();
    if (opCoMap[msg.sender].minted >= opCoMap[msg.sender].supply)
      revert InvalidSupply();
    emit Minted(msg.sender, citizenOpCoMap[msg.sender]);
    opCoMap[msg.sender].minted++;
    _mint(msg.sender, totalSupply++);
    mintedAdrs.push(msg.sender);
    delegationsMap[msg.sender] = 1;
    delegatedToMap[msg.sender] = msg.sender;
  }

  /// @notice Burn
  /// @dev Burns the soulbound ERC721.
  /// @param _id The token URI.
  function burn(uint256 _id) external onlyCitizen {
    if (balanceOf[msg.sender] != 1 || ownerOf[_id] != msg.sender)
      revert InvalidBurn();
    // TODO: What should happen on burn?
    //   _burn(_id);
    //
  }

  /// @notice Delegate the token
  /// @dev Delegate a singular token (without transfer) to another holder.
  /// @param _to The address the sender is delegating to.
  function delegate(address _to) external onlyCitizen {
    if (
      balanceOf[msg.sender] != 1 ||
      isDelegated(msg.sender) ||
      balanceOf[_to] == 0
    ) revert InvalidDelegation();
    delegatedToMap[msg.sender] = _to;
    delegationsMap[msg.sender] = 0;
    delegationsMap[_to] += 1;
    emit Delegated(msg.sender, _to);
  }

  /// @notice Un-Delegate the token
  /// @dev Un-Delegate a singular token (without transfer) from an address.
  /// @param _from The address the sender is un-delegating from.
  function undelegate(address _from) external onlyCitizen {
    if (
      balanceOf[msg.sender] != 1 ||
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

  function isOp(address _adr) public view returns (bool) {
    return isOpMap[_adr];
  }

  function isOpCo(address _adr) public view returns (bool) {
    return isOpCoMap[_adr];
  }

  function isCitizen(address _adr) public view returns (bool) {
    return isCitizenMap[_adr];
  }

  function isDelegated(address _adr) public view returns (bool) {
    return delegatedToMap[_adr] != _adr;
  }

  function getDelegatedTo(address _adr) public view returns (address) {
    return delegatedToMap[_adr];
  }

  function getOpAddresses() public view returns (address[] memory) {
    return opAdrs;
  }

  function getOpCoAddresses() public view returns (address[] memory) {
    return opCoAdrs;
  }

  function getMintedAddresses() public view returns (address[] memory) {
    return mintedAdrs;
  }

  function getOpCoSupply(address _adrs) public view returns (uint256) {
    return opCoMap[_adrs].supply;
  }

  function getOpCoAllocated(address _adrs) public view returns (uint256) {
    return opCoMap[_adrs].allocated;
  }

  function getOpCoCitizens(address _opco)
    public
    view
    returns (address[] memory)
  {
    return opCoMap[_opco].citizens;
  }

  function getOpCoMinted(address _opco) public view returns (uint256) {
    return opCoMap[_opco].minted;
  }

  function getCitizenDelegations(address _citizen)
    public
    view
    returns (uint256)
  {
    return delegationsMap[_citizen];
  }

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

  function getCitizenOpCo(address _citizen) public view returns (address) {
    return citizenOpCoMap[_citizen];
  }

  /*///////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

  // Make it ~*~ Soulbound ~*~
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override {
    revert Soulbound();
  }

  function withdraw() external onlyOwner {
    SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
  }

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
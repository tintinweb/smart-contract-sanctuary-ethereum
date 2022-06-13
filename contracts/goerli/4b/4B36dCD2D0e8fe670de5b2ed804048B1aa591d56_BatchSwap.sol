// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//Interface
abstract contract ERC20Interface {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function transfer(address recipient, uint256 amount) public virtual;
}

abstract contract ERC721Interface {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual;

  function balanceOf(address owner)
    public
    view
    virtual
    returns (uint256 balance);
}

abstract contract ERC1155Interface {
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual;
}

abstract contract CustomInterface {
  function bridgeSafeTransferFrom(
    address dapp,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual;
}

contract BatchSwap is Ownable, Pausable, IERC721Receiver, IERC1155Receiver {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  // Struct Payment
  struct PaymentStruct {
    bool status;
    uint256 value;
  }

  // Swap Struct
  struct SwapStruct {
    address dapp; // dapp asset contract address, needs to be white-listed
    AssetType typeStd; // the type? (TODO maybe change to enum)
    uint256[] tokenId; // list of asset ids (only 0 used i ncase of non-erc1155)
    uint256[] blc; //
    bytes data;
  }

  // Swap Status
  enum SwapStatus {
    Pending,
    Completed,
    Canceled
  }
  enum AssetType {
    ERC20,
    ERC721,
    ERC1155,
    CUSTOM
  }

  // SwapIntent Struct
  struct SwapIntent {
    uint256 id;
    address payable addressOne;
    uint256 valueOne; // must
    address payable addressTwo; // must
    uint256 valueTwo; //  must
    uint256 swapStart;
    uint256 swapEnd;
    uint256 swapFee;
    SwapStatus status;
  }

  address public swapVaultNFT; // is used to list users that pay no fees (give them vip nfts)
  address payable public vaultAddress; // to pay fees

  mapping(address => address) public dappRelations; // to specify contracts for custom interfaced smart contracts
  
  bytes32 public _whiteListMerkleRoot; // whitelist of tokens

  bool public whiteListEnabled;

  Counters.Counter private _swapIds;

  // Flag for the createSwap
  bool private swapFlag;

  // NFT Mapping
  mapping(uint256 => SwapStruct[]) public nftsOne; // assets to trade for initiators
  mapping(uint256 => SwapStruct[]) public nftsTwo; // assets to trade for confirtmators

  // Mapping key/value for get the swap infos
  mapping(address => SwapIntent[]) public swapList; // storing swaps of each user
  mapping(uint256 => uint256) public swapMatch; // to check swap_id => number in order of the user's swaps

  // Struct for the payment rules
  PaymentStruct public payment;

  // Events
  event SwapEvent(
    address indexed _creator,
    uint256 indexed time,
    SwapStatus indexed _status,
    uint256 _swapId,
    address _swapCounterPart
  );

  // Events
  event EditCounterPartEvent(
    address _creator,
    uint256 time,
    uint256 _swapId,
    address _swapCounterPart
  );
  event WhiteListChange(address _dapp, bool _status);
  event PaymentReceived(address indexed _payer, uint256 _value);

  constructor(address _swapVaultNFT, address _vaultAddress) {
    swapVaultNFT = _swapVaultNFT;
    vaultAddress = payable(_vaultAddress);
  }

  receive() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  //Interface IERC721/IERC1155
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata id,
    uint256[] calldata value,
    bytes calldata data
  ) external override returns (bytes4) {
    return
      bytes4(
        keccak256(
          "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
        )
      );
  }

  // Get Trade fees
  function getWeiPayValueAmount() external view returns (uint256) {
    return payment.value;
  }

  // Get swap infos
  function getSwapListByAddress(address _creator)
    external
    view
    returns (SwapIntent[] memory)
  {
    return swapList[_creator];
  }

  // Get swap infos
  function getSwapIntentByAddress(address _creator, uint256 _swapId)
    external
    view
    returns (SwapIntent memory)
  {
    return swapList[_creator][swapMatch[_swapId]];
  }

  // Get SwapStructLength
  function getSwapStructSize(uint256 _swapId, bool _nfts)
    external
    view
    returns (uint256)
  {
    if (_nfts) return nftsOne[_swapId].length;
    else return nftsTwo[_swapId].length;
  }

  // Get SwapStruct
  function getSwapStruct(
    uint256 _swapId,
    bool _nfts,
    uint256 _index
  ) external view returns (SwapStruct memory) {
    if (_nfts) return nftsOne[_swapId][_index];
    else return nftsTwo[_swapId][_index];
  }

  // Get SwapStruct
  function getSwapStructs(uint256 _swapId, bool _nfts)
    external
    view
    returns (SwapStruct[] memory)
  {
    if (_nfts) return nftsOne[_swapId];
    else return nftsTwo[_swapId];
  }

  function supportsInterface(bytes4 interfaceID)
    external
    view
    virtual
    override
    returns (bool)
  {
    return interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
  }

  function initSwapIntent(SwapIntent memory _swapIntent) private view returns (SwapIntent memory) {
    PaymentStruct memory paymentCache = payment;
    if (paymentCache.status) {
      if (ERC721Interface(swapVaultNFT).balanceOf(msg.sender) == 0) {
        _swapIntent.valueOne += paymentCache.value;
        _swapIntent.swapFee = paymentCache.value;
      } else {
        _swapIntent.swapFee = 0;
      }
    }
    
    _swapIntent.addressOne = payable(msg.sender); // to ensure that only sender can create swap intents
    _swapIntent.id = _swapIds.current(); // set swap id
    _swapIntent.swapStart = block.timestamp; // set the time when swap started
    _swapIntent.swapEnd = 0; // will be set to non-zero on close/cancel
    _swapIntent.status = SwapStatus.Pending; // identify the status of the swap

    return _swapIntent;
  }

  // Create Swap
  function createSwapIntent(
    SwapIntent memory _swapIntent,
    SwapStruct[] memory _nftsOne,
    SwapStruct[] memory _nftsTwo,
    bytes32[][] calldata merkleProofOne,
    bytes32[][] calldata merkleProofTwo
  ) external payable whenNotPaused {
    require(msg.value >= _swapIntent.valueOne, "Bigger eth value required"); // check the payment satisfies

    _swapIntent = initSwapIntent(_swapIntent);

    swapMatch[_swapIds.current()] = swapList[msg.sender].length; // specify the number of the swap in the list of user swaps
    swapList[msg.sender].push(_swapIntent); // add the swpa intent to the user

    uint256 i;
    bool whiteListEnabledCache = whiteListEnabled;

    if (whiteListEnabledCache) {
      for (i = 0; i < _nftsOne.length; i++) {
        bool isWhitelisted = MerkleProof.verify(merkleProofOne[i], _whiteListMerkleRoot, keccak256(abi.encodePacked(_nftsOne[i].dapp)));
        require(isWhitelisted, "Token is not supported"); // check if Dapp is supported
      }
      for (i = 0; i < _nftsTwo.length; i++) {
        bool isWhitelisted = MerkleProof.verify(merkleProofTwo[i], _whiteListMerkleRoot, keccak256(abi.encodePacked(_nftsTwo[i].dapp)));
        require(isWhitelisted, "Token is not supported"); // check if Dapp is supported
      }
    }
    for (i = 0; i < _nftsOne.length; i++) {
      nftsOne[_swapIntent.id].push(_nftsOne[i]); // fill swap with initalizer nfts
    }
    for (i = 0; i < _nftsTwo.length; i++) {
      nftsTwo[_swapIntent.id].push(_nftsTwo[i]); // fill swap with respondent nfts
    }

    for (i = 0; i < _nftsOne.length; i++) {
      if (_nftsOne[i].typeStd == AssetType.ERC20) {
        ERC20Interface(_nftsOne[i].dapp).transferFrom(
          _swapIntent.addressOne,
          address(this),
          _nftsOne[i].blc[0]
        );
      } else if (_nftsOne[i].typeStd == AssetType.ERC721) {
        uint256 tokenIdIndex;
        for (
          tokenIdIndex = 0;
          tokenIdIndex < _nftsOne[i].tokenId.length;
          tokenIdIndex++
        ) {
          ERC721Interface(_nftsOne[i].dapp).safeTransferFrom(
            _swapIntent.addressOne,
            address(this),
            _nftsOne[i].tokenId[tokenIdIndex],
            _nftsOne[i].data
          );
        }
      } else if (_nftsOne[i].typeStd == AssetType.ERC1155) {
        ERC1155Interface(_nftsOne[i].dapp).safeBatchTransferFrom(
          _swapIntent.addressOne,
          address(this),
          _nftsOne[i].tokenId,
          _nftsOne[i].blc,
          _nftsOne[i].data
        );
      } else {
        CustomInterface(dappRelations[_nftsOne[i].dapp]).bridgeSafeTransferFrom(
            _nftsOne[i].dapp,
            _swapIntent.addressOne,
            dappRelations[_nftsOne[i].dapp],
            _nftsOne[i].tokenId,
            _nftsOne[i].blc,
            _nftsOne[i].data
          );
      }
    }

    emit SwapEvent(
      msg.sender,
      block.timestamp,
      _swapIntent.status,
      _swapIntent.id,
      _swapIntent.addressTwo
    );
    _swapIds.increment();
  }

  // Close the swap
  function closeSwapIntent(address _swapCreator, uint256 _swapId, bytes32[][] calldata merkleProofOne, bytes32[][] calldata merkleProofTwo)
    external
    payable
    whenNotPaused
  {
    SwapIntent memory swapIntentCache = swapList[_swapCreator][
      swapMatch[_swapId]
    ];
    require(
      swapIntentCache.status == SwapStatus.Pending,
      "Swap Status is not opened"
    );
    require(
      swapIntentCache.addressTwo == msg.sender,
      "Not the interested counterpart"
    );

    uint256 valueRequired = swapIntentCache.valueTwo;
    PaymentStruct memory paymentCache = payment;
    if (paymentCache.status) {
      if (ERC721Interface(swapVaultNFT).balanceOf(msg.sender) == 0) {
        valueRequired += paymentCache.value;
        if (paymentCache.value + swapIntentCache.swapFee > 0)
          vaultAddress.transfer(paymentCache.value + swapIntentCache.swapFee);
      } else {
        if (swapIntentCache.swapFee > 0)
          vaultAddress.transfer(swapIntentCache.swapFee);
      }
    }

    require(msg.value >= valueRequired, "Bigger eth value required"); // check the payment satisfies
    delete valueRequired;
    delete paymentCache;

    swapIntentCache.addressTwo = payable(msg.sender); // to make address payable
    swapIntentCache.swapEnd = block.timestamp; // set time of swap closing (TODO maybe move in the end)
    swapIntentCache.status = SwapStatus.Completed; // (TODO maybe move in the end)

    swapList[_swapCreator][swapMatch[_swapId]] = swapIntentCache;

    SwapStruct[] memory _nftsOne = nftsOne[_swapId];
    SwapStruct[] memory _nftsTwo = nftsTwo[_swapId];

    if (whiteListEnabled) {
      for (uint i = 0; i < _nftsOne.length; i++) {
        bool isWhitelisted = MerkleProof.verify(merkleProofOne[i], _whiteListMerkleRoot, keccak256(abi.encodePacked(_nftsOne[i].dapp)));
        require(isWhitelisted, "Token is not supported"); // check if Dapp is supported
      }
      for (uint i = 0; i < _nftsTwo.length; i++) {
        bool isWhitelisted = MerkleProof.verify(merkleProofTwo[i], _whiteListMerkleRoot, keccak256(abi.encodePacked(_nftsTwo[i].dapp)));
        require(isWhitelisted, "Token is not supported"); // check if Dapp is supported
      }
    }
    //From Owner 1 to Owner 2
    for (uint i = 0; i < _nftsOne.length; i++) {
      if (_nftsOne[i].typeStd == AssetType.ERC20) {
        ERC20Interface(_nftsOne[i].dapp).transfer(
          swapIntentCache.addressTwo,
          _nftsOne[i].blc[0]
        );
      } else if (_nftsOne[i].typeStd == AssetType.ERC721) {
        uint256 tokenIdIndex;
        for (
          tokenIdIndex = 0;
          tokenIdIndex < _nftsOne[i].tokenId.length;
          tokenIdIndex++
        ) {
          ERC721Interface(_nftsOne[i].dapp).safeTransferFrom(
            address(this),
            swapIntentCache.addressTwo,
            _nftsOne[i].tokenId[tokenIdIndex],
            _nftsOne[i].data
          );
        }
      } else if (_nftsOne[i].typeStd == AssetType.ERC1155) {
        ERC1155Interface(_nftsOne[i].dapp).safeBatchTransferFrom(
          address(this),
          swapIntentCache.addressTwo,
          _nftsOne[i].tokenId,
          _nftsOne[i].blc,
          _nftsOne[i].data
        );
      } else {
        CustomInterface(dappRelations[_nftsOne[i].dapp]).bridgeSafeTransferFrom(
            _nftsOne[i].dapp,
            dappRelations[_nftsOne[i].dapp],
            swapIntentCache.addressTwo,
            _nftsOne[i].tokenId,
            _nftsOne[i].blc,
            _nftsOne[i].data
          );
      }
    }
    if (swapIntentCache.valueOne > 0)
      swapIntentCache.addressTwo.transfer(swapIntentCache.valueOne);

    //From Owner 2 to Owner 1
    for (uint i = 0; i < _nftsTwo.length; i++) {
      if (_nftsTwo[i].typeStd == AssetType.ERC20) {
        ERC20Interface(_nftsTwo[i].dapp).transferFrom(
          swapIntentCache.addressTwo,
          swapIntentCache.addressOne,
          _nftsTwo[i].blc[0]
        );
      } else if (_nftsTwo[i].typeStd == AssetType.ERC721) {
        uint256 tokenIdIndex;
        for (
          tokenIdIndex = 0;
          tokenIdIndex < _nftsTwo[i].tokenId.length;
          tokenIdIndex++
        ) {
          ERC721Interface(_nftsTwo[i].dapp).safeTransferFrom(
            swapIntentCache.addressTwo,
            swapIntentCache.addressOne,
            _nftsTwo[i].tokenId[tokenIdIndex],
            _nftsTwo[i].data
          );
        }
      } else if (_nftsTwo[i].typeStd == AssetType.ERC1155) {
        ERC1155Interface(_nftsTwo[i].dapp).safeBatchTransferFrom(
          swapIntentCache.addressTwo,
          swapIntentCache.addressOne,
          _nftsTwo[i].tokenId,
          _nftsTwo[i].blc,
          _nftsTwo[i].data
        );
      } else {
        CustomInterface(dappRelations[_nftsTwo[i].dapp]).bridgeSafeTransferFrom(
            _nftsTwo[i].dapp,
            swapIntentCache.addressTwo,
            swapIntentCache.addressOne,
            _nftsTwo[i].tokenId,
            _nftsTwo[i].blc,
            _nftsTwo[i].data
          );
      }
    }
    if (swapIntentCache.valueTwo > 0)
      swapIntentCache.addressOne.transfer(swapIntentCache.valueTwo);

    emit SwapEvent(
      msg.sender,
      block.timestamp,
      SwapStatus.Completed,
      _swapId,
      _swapCreator // temp
    );
  }

  // Cancel Swap
  function cancelSwapIntent(address _swapCreator, uint256 _swapId) external {
    SwapIntent memory swapIntentCache = swapList[_swapCreator][
      swapMatch[_swapId]
    ];
    SwapStruct[] memory _nftsOne = nftsOne[_swapId];

    require(
      msg.sender == swapIntentCache.addressOne ||
        msg.sender == swapIntentCache.addressTwo,
      "Not the interested counterpart"
    );
    require(
      swapIntentCache.status == SwapStatus.Pending,
      "Swap Status is not opened"
    );
    //Rollback
    if (swapIntentCache.swapFee > 0)
      payable(msg.sender).transfer(swapIntentCache.swapFee);

    swapIntentCache.swapEnd = block.timestamp;
    swapIntentCache.status = SwapStatus.Canceled;
    swapList[_swapCreator][swapMatch[_swapId]] = swapIntentCache;

    uint256 i;
    for (i = 0; i < _nftsOne.length; i++) {
      if (_nftsOne[i].typeStd == AssetType.ERC20) {
        ERC20Interface(_nftsOne[i].dapp).transfer(
          swapIntentCache.addressOne,
          _nftsOne[i].blc[0]
        );
      } else if (_nftsOne[i].typeStd == AssetType.ERC721) {
        uint256 tokenIdIndex;
        for (
          tokenIdIndex = 0;
          tokenIdIndex < _nftsOne[i].tokenId.length;
          tokenIdIndex++
        ) {
          ERC721Interface(_nftsOne[i].dapp).safeTransferFrom(
            address(this),
            swapIntentCache.addressOne,
            _nftsOne[i].tokenId[tokenIdIndex],
            _nftsOne[i].data
          );
        }
      } else if (_nftsOne[i].typeStd == AssetType.ERC1155) {
        ERC1155Interface(_nftsOne[i].dapp).safeBatchTransferFrom(
          address(this),
          swapIntentCache.addressOne,
          _nftsOne[i].tokenId,
          _nftsOne[i].blc,
          _nftsOne[i].data
        );
      } else {
        CustomInterface(dappRelations[_nftsOne[i].dapp]).bridgeSafeTransferFrom(
            _nftsOne[i].dapp,
            dappRelations[_nftsOne[i].dapp],
            swapIntentCache.addressOne,
            _nftsOne[i].tokenId,
            _nftsOne[i].blc,
            _nftsOne[i].data
          );
      }
    }

    if (swapIntentCache.valueOne > 0)
      swapIntentCache.addressOne.transfer(swapIntentCache.valueOne);

    emit SwapEvent(
      msg.sender,
      block.timestamp,
      SwapStatus.Canceled,
      _swapId,
      address(0)
    );
  }

  // Edit CounterPart Address
  function editCounterPart(uint256 _swapId, address payable _counterPart)
    external
  {
    SwapIntent memory swapIntentCache = swapList[msg.sender][
      swapMatch[_swapId]
    ];
    require(
      swapIntentCache.id == _swapId && msg.sender == swapIntentCache.addressOne,
      "Only for swap initiator"
    );
    swapList[msg.sender][swapMatch[_swapId]].addressTwo = _counterPart;

    emit EditCounterPartEvent(
      msg.sender,
      block.timestamp,
      _swapId,
      _counterPart
    );
  }

  // Set SWAPVAULT NFT address
  function setSwapNftAddress(address _swapVaultNFT) external onlyOwner {
    swapVaultNFT = _swapVaultNFT;
  }

  // Set Vault address
  function setVaultAddress(address payable _vaultAddress) external onlyOwner {
    vaultAddress = _vaultAddress;
  }

  // Handle dapp relations for the bridges
  function setDappRelation(address _dapp, address _customInterface)
    external
    onlyOwner
  {
    dappRelations[_dapp] = _customInterface;
  }

  // Handle the whitelist
  function setWhitelist(bytes32 merkleRootTreeHash) external onlyOwner {
    _whiteListMerkleRoot = merkleRootTreeHash;
  }

  // Turn on/off whitelisting by setting opposite boolean
  function toggleWhitelistEnabled() external onlyOwner {
    whiteListEnabled = !whiteListEnabled;
  }

  // Set the payment
  function setPayment(bool _status, uint256 _value)
    external
    onlyOwner
    whenNotPaused
  {
    payment.status = _status;
    payment.value = _value * (1 wei);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
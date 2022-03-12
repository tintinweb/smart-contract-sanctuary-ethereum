pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./VaultHandlerV8.sol";

contract ERC721Factory is OwnableUpgradeable {

  address public handlerAddress;
  address public erc721Implementation;

  event ERC721Created(address indexed newThingAddress, address indexed libraryAddress);
  address[] public ERC721Clones;

  function initialize(address _handlerAddress) public initializer {
    __Ownable_init();
    handlerAddress = _handlerAddress;
    erc721Implementation = address(new EmblemVault());
  }

  function updateHandler(address _handlerAddress) public onlyOwner {
    handlerAddress = _handlerAddress;
  }

  function getOwner() public view returns (address _owner) {
    return owner();
  }

  function createERC721(address _newOwner) public onlyOwner returns (address clone){
    address _clone = ClonesUpgradeable.clone(erc721Implementation);
    VaultHandlerV8 handler = VaultHandlerV8(handlerAddress);
    if (handler.isRegistered(address(this), 8)) { // if factory registered with handler
      handler.registerContract(_clone, 2);
    }
    EmblemVault(_clone).init(address(this)); // owned by this contract
    EmblemVault(_clone).registerContract(handlerAddress, 3); // register handler on erc721
    EmblemVault(_clone).transferOwnership(_newOwner); // transfer to newOwner
    ERC721Clones.push(_clone);
    emit ERC721Created(_clone, erc721Implementation);
    return _clone;
  }

  function version() virtual public view returns (uint256 _version) {
    return 1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

//     ______          __    __                          
//    / ____/___ ___  / /_  / /__  ____ ___              
//   / __/ / __ `__ \/ __ \/ / _ \/ __ `__ \             
//  / /___/ / / / / / /_/ / /  __/ / / / / /             
// /_____/_/ /_/ /_/_.___/_/\___/_/ /_/ /_/              
// | |  / /___ ___  __/ / /_                             
// | | / / __ `/ / / / / __/                             
// | |/ / /_/ / /_/ / / /_                               
// |___/\__,_/\__,_/_/\__/                               
//     __  __                ____                   ____ 
//    / / / /___ _____  ____/ / /__  _____   _   __( __ )
//   / /_/ / __ `/ __ \/ __  / / _ \/ ___/  | | / / __  |
//  / __  / /_/ / / / / /_/ / /  __/ /      | |/ / /_/ / 
// /_/ /_/\__,_/_/ /_/\__,_/_/\___/_/       |___/\____/  

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./BasicERC20.sol";
import "./EmblemVault.sol";
import "./ConfigurableERC20.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./Storage.sol";
import "./BalanceStorage.sol";
import "./Claimed.sol";
import "./Balance.sol";
import "./NFTrade_v2.sol";
import "./NFTrade_v3.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./HasCallbacks.sol";
import "./TokenStaking.sol";

contract VaultHandlerV8 is ReentrancyGuard, HasCallbacks, ERC165 {
    
    using SafeMath for uint256;
    string public metadataBaseUri = "https://api.emblemvault.io/s:evmetadata/meta/";
    // bool public initialized;
    // address public nftAddress;
    address public recipientAddress;
    // address public paymentAddress;
    // uint256 public price;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    // bytes4 private constant _INTERFACE_ID_HANDLER = bytes4(keccak256("handler"));
    bool public shouldBurn = false;
    
    // struct PreTransfer {
    //     string payload;
    //     bytes32 preImage;
    //     address _from;
    // }

    // mapping(address => mapping(uint => PreTransfer)) preTransfers;
    // mapping(address => mapping(uint => mapping(uint => PreTransfer))) preTransfersByIndex;
    // mapping(address => mapping(uint => uint)) preTransferCounts;
    
    mapping(address => bool) public witnesses;
    mapping(uint256 => bool) usedNonces;
    
    constructor() {
        addWitness(owner);
        
        // nftAddress = _nftAddress;
        // paymentAddress = _paymentAddress;
        recipientAddress = _msgSender();
        // initialized = true;
        // uint decimals = BasicERC20(paymentAddress).decimals();
        // price = _price.mul(10 ** decimals);
        // _registerInterface(_INTERFACE_ID_HANDLER);
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function claim(address _nftAddress, uint256 tokenId) public nonReentrant isRegisteredContract(_nftAddress) {
        Claimed claimer = Claimed(registeredOfType[6][0]);
        bytes32[] memory proof;
        
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            uint256 serialNumber = serialized.getFirstSerialByOwner(_msgSender(), tokenId);
            require(serialized.getTokenIdForSerialNumber(serialNumber) == tokenId, "Invalid tokenId serialnumber combination");
            require(serialized.getOwnerOfSerial(serialNumber) == _msgSender(), "Not owner of serial number");
            require(!claimer.isClaimed(_nftAddress, serialNumber, proof), "Already Claimed");
            IERC1155(_nftAddress).burn(_msgSender(), tokenId, 1);
            claimer.claim(_nftAddress, serialNumber, _msgSender());
        } else {            
            require(!claimer.isClaimed(_nftAddress, tokenId, proof), "Already Claimed");
            IERC721 token = IERC721(_nftAddress);
            require(token.ownerOf(tokenId) == _msgSender(), "Not Token Owner");
            token.burn(tokenId);
            claimer.claim(_nftAddress, tokenId, _msgSender());
        }
        executeCallbacksInternal(_nftAddress, _msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.CLAIM);
    }
    
    // function buyWithSignature(address _nftAddress, address _to, uint256 _tokenId, string calldata _payload, uint256 _nonce, bytes calldata _signature) public nonReentrant {
    //     IERC20Token paymentToken = IERC20Token(paymentAddress);
    //     if (shouldBurn && price > 0) {
    //         require(paymentToken.transferFrom(msg.sender, address(this), price), 'Transfer ERROR'); // Payment sent to recipient
    //         BasicERC20(paymentAddress).burn(price);
    //     } else if(price > 0) {
    //         require(paymentToken.transferFrom(msg.sender, address(recipientAddress), price), 'Transfer ERROR'); // Payment sent to recipient
    //     }
    //     address signer = getAddressFromSignatureMint(_nftAddress, _to, _tokenId, _nonce, _payload, _signature);
    //     require(witnesses[signer], 'Not Witnessed');
    //     usedNonces[_nonce] = true;
    //     string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
    //     if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
    //         IERC1155(_nftAddress).mint(_to, _tokenId, 1);
    //     } else {
    //         IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
    //     }
    // }

    function buyWithSignedPrice(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, string calldata _payload, uint256 _nonce, bytes calldata _signature) public nonReentrant {
        IERC20Token paymentToken = IERC20Token(_payment);
        if (shouldBurn) {
            require(paymentToken.transferFrom(msg.sender, address(this), _price), 'Transfer ERROR'); // Payment sent to recipient
            BasicERC20(_payment).burn(_price);
        } else {
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), _price), 'Transfer ERROR'); // Payment sent to recipient
        }
        address signer = getAddressFromSignature(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _payload, _signature);
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[_nonce] = true;
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).mint(_to, _tokenId, 1);
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
        }
    }

    function mint(address _nftAddress, address _to, uint256 _tokenId, string calldata _uri, string calldata _payload, uint256 amount) external onlyOwner {
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).mint(_to, _tokenId, amount);
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
        }        
    }

    function moveVault(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 nonce, bytes calldata signature) external nonReentrant isRegisteredContract(_from) isRegisteredContract(_to)  {
        require(_from != _to, 'Cannot move vault to same address');
        address signer = getAddressFromSignatureMove(_from, _to, tokenId, newTokenId, nonce, signature);
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[nonce] = true;
        if (checkInterface(_from, _INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'from: TokenIds must be different for ERC1155');
            uint256 currentBalance = IERC1155(_from).balanceOf(_msgSender(), tokenId);
            require(currentBalance > 0, 'from: Not owner of vault');
            IERC1155(_from).burn(_msgSender(), tokenId, 1);
            uint256 newBalance = IERC1155(_from).balanceOf(_msgSender(), tokenId);
            require(newBalance == currentBalance.sub(1), 'from: Not Burnt');
        } else {
            require(IERC721(_from).ownerOf(tokenId) == _msgSender(), 'from: Not owner of vault');
            IERC721(_from).burn(tokenId);
            tryERC721BalanceCheck(_from, tokenId, 'Not Burnt');
        }
        if (checkInterface(_to, _INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'to: TokenIds must be different for ERC1155');            
            IERC1155(_to).mint(_msgSender(), newTokenId, 1);
        } else {
            tryERC721BalanceCheck(_to, newTokenId, 'NFT Already Exists');
            string memory _uri = concat(metadataBaseUri, uintToStr(newTokenId));
            IERC721(_to).mint(_msgSender(), newTokenId, _uri, "");
        }
    }

    function tryERC721BalanceCheck(address _from, uint256 tokenId, string memory reason) public returns(uint256 returnedAmount){
        (bool success, bytes memory returnData) =
            address(_from).call( // This creates a low level call to the token
                abi.encodePacked( // This encodes the function to call and the parameters to pass to that function
                    IERC721(_from).ownerOf.selector, // This is the function identifier of the function we want to call
                    abi.encode(tokenId) // This encodes the parameter we want to pass to the function
                )
            );
        if (success) { 
            revert(reason);                
        } else { 
            (returnedAmount) = abi.decode(returnData, (uint256));
        }
    }    
    
    function toggleShouldBurn() public onlyOwner {
        shouldBurn = !shouldBurn;
    }
    
    /* Transfer with code */
    function addWitness(address _witness) public onlyOwner {
        witnesses[_witness] = true;
    }

    function removeWitness(address _witness) public onlyOwner {
        witnesses[_witness] = false;
    }

    // function transferToStaking(address _nftAddress, address _to, uint256 tokenId, uint256 value) external nonReentrant {
    //     IERC721 nftToken = IERC721(_nftAddress);
    //     nftToken.safeTransferFrom(_msgSender(), _to, tokenId, abi.encode(_nftAddress, value));
    // }

    function getAddressFromSignatureHash(bytes32 _hash, bytes calldata signature) public pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }

    function getAddressFromSignature(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, uint256 _nonce, string calldata _payload, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        bytes32 _hash = keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _payload));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignature(address _to, uint256 _tokenId, uint256 _nonce, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        bytes32 _hash = keccak256(abi.encodePacked(_to, _tokenId, _nonce));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignatureMint(address _nftAddress, address _to, uint256 _tokenId, uint256 _nonce, string calldata payload, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        bytes32 _hash = keccak256(abi.encodePacked(_nftAddress, _to, _tokenId, _nonce, payload));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignatureMove(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 _nonce, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        bytes32 _hash = keccak256(abi.encodePacked(_from, _to, tokenId, newTokenId, _nonce));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function isWitnessed(bytes32 _hash, bytes calldata signature) public view returns (bool) {
        address addressFromSig = recoverSigner(_hash, signature);
        return witnesses[addressFromSig];
    }
    
    // function transferWithCode(address _nftAddress, uint256 _tokenId, string calldata code, address _to, uint256 _nonce,  bytes calldata signature) public nonReentrant {
    //     require(witnesses[getAddressFromSignature(_to, _tokenId, _nonce, signature)], 'Not Witnessed');
    //     IERC721 nftToken = IERC721(_nftAddress);
    //     PreTransfer memory preTransfer = preTransfers[_nftAddress][_tokenId];
    //     require(preTransfer.preImage == sha256(abi.encodePacked(code)), 'Code does not match'); // Payload should match
    //     nftToken.transferFrom(preTransfer._from, _to,  _tokenId);
    //     delete preTransfers[_nftAddress][_tokenId];
    //     delete preTransfersByIndex[_nftAddress][_tokenId][preTransferCounts[_nftAddress][_tokenId]];
    //     preTransferCounts[_nftAddress][_tokenId] = preTransferCounts[_nftAddress][_tokenId].sub(1);
    //     usedNonces[_nonce] = true;
    // }
    
    // function addPreTransfer(address _nftAddress, uint256 _tokenId, bytes32 preImage) public nonReentrant {
    //     require(!_duplicatePretransfer(_nftAddress, _tokenId), 'Duplicate PreTransfer');
    //     preTransferCounts[_nftAddress][_tokenId] = preTransferCounts[_nftAddress][_tokenId].add(1);
    //     preTransfers[_nftAddress][_tokenId] = PreTransfer("payload", preImage, msg.sender);
    //     preTransfersByIndex[_nftAddress][_tokenId][preTransferCounts[_nftAddress][_tokenId]] = preTransfers[_nftAddress][_tokenId];
    // }
    
    // function _duplicatePretransfer(address _nftAddress, uint256 _tokenId) internal view returns (bool) {
    //     string memory data = preTransfers[_nftAddress][_tokenId].payload;
    //     bytes32 NULL = keccak256(bytes(''));
    //     return keccak256(bytes(data)) != NULL;
    // }
    
    // function deletePreTransfer(address _nftAddress, uint256 _tokenId) public nonReentrant {
    //     require(preTransfers[_nftAddress][_tokenId]._from == msg.sender, 'PreTransfer does not belong to sender');
    //     delete preTransfersByIndex[_nftAddress][_tokenId][preTransferCounts[_nftAddress][_tokenId]];
    //     preTransferCounts[_nftAddress][_tokenId] = preTransferCounts[_nftAddress][_tokenId].sub(1);
    //     delete preTransfers[_nftAddress][_tokenId];
    // }
    
    // function getPreTransfer(address _nftAddress, uint256 _tokenId) public view returns (PreTransfer memory) {
    //     return preTransfers[_nftAddress][_tokenId];
    // }
    
    // function checkPreTransferImage(string memory image, bytes32 preImage) public pure returns (bytes32, bytes32, bool) {
    //     bytes32 calculated = sha256(abi.encodePacked(image));
    //     bytes32 preBytes = preImage;
    //     return (calculated, preBytes, calculated == preBytes);
    // }
    
    // function getPreTransferCount(address _nftAddress, uint256 _tokenId) public view returns (uint length) {
    //     return preTransferCounts[_nftAddress][_tokenId];
    // }
    
    // function getPreTransferByIndex(address _nftAddress, uint256 _tokenId, uint index) public view returns (PreTransfer memory) {
    //     return preTransfersByIndex[_nftAddress][_tokenId][index];
    // }
    
    function changeMetadataBaseUri(string calldata _uri) public onlyOwner {
        metadataBaseUri = _uri;
    }
    
    // function transferPaymentOwnership(address newOwner) external onlyOwner {
    //     Ownable paymentToken = Ownable(paymentAddress);
    //     paymentToken.transferOwnership(newOwner);
    // }
    
    function transferNftOwnership(address _nftAddress, address newOwner) external onlyOwner {
        Ownable nftToken = Ownable(_nftAddress);
        nftToken.transferOwnership(newOwner);
    }
    
    function changeName(address _nftAddress, string calldata name, string calldata symbol) external onlyOwner {
        IERC721 nftToken = IERC721(_nftAddress);
        nftToken.changeName(name, symbol);
    }
    
    function updateTokenUri(address _nftAddress, uint256 _tokenId,string memory _uri) external onlyOwner {
        IERC721 nftToken = IERC721(_nftAddress);
        nftToken.updateTokenUri(_tokenId, _uri);
    }
    
    // function getPaymentDecimals() public view returns (uint8){
    //     BasicERC20 token = BasicERC20(paymentAddress);
    //     return token.decimals();
    // }
    
    // function changePayment(address payment) public onlyOwner {
    //    paymentAddress = payment;
    // }

    function changeRecipient(address _recipient) public onlyOwner {
       recipientAddress = _recipient;
    }
    
    // function changeNft(address token) public onlyOwner {
    //     nftAddress = token;
    // }
    
    // function changePrice(uint256 _price) public onlyOwner {
    //     uint decimals = BasicERC20(paymentAddress).decimals();
    //     price = _price.mul(10 ** decimals);
    // }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    // function toBytes(address a) public pure returns (bytes memory b){
    //     assembly {
    //         let m := mload(0x40)
    //         a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    //         mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
    //         mstore(0x40, add(m, 52))
    //         b := m
    //     }
    // }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function recoverSigner(bytes32 hash, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }
    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }
    // function bytesToUint(bytes20 b) public pure returns (uint256){
    //     uint256 number;
    //     for(uint i=0;i<b.length;i++){
    //         number = number + uint8(b[i]);
    //     }
    //     return number;
    // }
    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }    
    function toString(uint256 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }    
    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }    
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

pragma solidity 0.8.4;
interface BasicERC20 {
    function burn(uint256 value) external;
    function mint(address account, uint256 amount) external;
    function decimals() external view returns (uint8);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC165.sol";
import "./HasRegistration.sol";
import "./HasCallbacks.sol";
// import "./IHandler.sol";

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Metadata
{

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{
  
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

 
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}


/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  ERC721,
  ERC165,
  HasRegistration,
  HasCallbacks
{
  using SafeMath for uint256;
  using AddressUtils for address;

  /**
   * List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can recieve NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of his tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], NOT_OWNER_OR_OPERATOR);
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }


  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    _registerInterface(0x80ac58cd);
  }
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }


  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually preforms the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
      IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, _to, _tokenId, IHandlerCallback.CallbackType.TRANSFER);
    }

    emit Transfer(from, _to, _tokenId);
  }

  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }


  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }

}

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
abstract contract NFTokenEnumerableMetadata is
    NFToken,
    ERC721Metadata,
    ERC721Enumerable
{

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;
  
    /**
   * @dev An uri to represent the metadata for this contract.
   */
  string internal nftContractMetadataUri;

  /**
   * @dev Mapping from NFT ID to metadata uri.
   */
  mapping (uint256 => string) internal idToUri;
  
  /**
   * @dev Mapping from NFT ID to encrypted value.
   */
  mapping (uint256 => string) internal idToPayload;
  bool initialized = false;
  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   */
  constructor() {
    // init(_msgSender());
  }

  // function init(address _owner) public {
  //   require(!initialized, "Already Initialized");
  //   owner = _owner;
  //   _registerInterface(0x5b5e139f); // ERC721Metadata
  //   _registerInterface(0x780e9d63); // ERC721Enumerable
  //   initialized = true;
  // }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToUri[_tokenId];
  }
  
    /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenPayload(
    uint256 _tokenId
  )
    external
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return idToPayload[_tokenId];
  }

  /**
   * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
   * @notice This is an internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId Id for which we want URI.
   * @param _uri String representing RFC 3986 URI.
   */
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }
  
function _setTokenPayload(
    uint256 _tokenId,
    string memory _payload
  )
    internal
    validNFToken(_tokenId)
  {
    idToPayload[_tokenId] = _payload;
  }
  
  /**
   * List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant INVALID_INDEX = "005007";

  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal tokens;

  /**
   * @dev Mapping from token ID to its index in global tokens array.
   */
  mapping(uint256 => uint256) internal idToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs.
   */
  mapping(address => uint256[]) internal ownerToIds;

  /**
   * @dev Mapping from NFT ID to its index in the owner tokens list.
   */
  mapping(uint256 => uint256) internal idToOwnerIndex;
  
  /**
   * @dev Returns the count of all existing NFTokens.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    override
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);
    
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
    
    if (bytes(idToPayload[_tokenId]).length != 0)
    {
      delete idToPayload[_tokenId];
    }
    
    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }

  /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }

}

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract EmblemVault is
  NFTokenEnumerableMetadata
{

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor() {
    init(_msgSender());
  }

  function init(address _owner) public {
    require(!initialized, "Already Initialized");
    owner = _owner;
    nftName = "Emblem Vault V2";
    nftSymbol = "Emblem.pro";
    _registerInterface(0x5b5e139f); // ERC721Metadata
    _registerInterface(0x780e9d63); // ERC721Enumerable
    initialized = true;
  }
  
  function changeName(string calldata name, string calldata symbol) external onlyOwner {
      nftName = name;
      nftSymbol = symbol;
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    super._setTokenPayload(_tokenId, _payload);
    if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
      IHandlerCallback(_msgSender()).executeCallbacks(address(0), _to, _tokenId, IHandlerCallback.CallbackType.MINT);  
    }
  }
  
  function burn(uint256 _tokenId) external canTransfer(_tokenId) {
    super._burn(_tokenId);
  }
  
  function contractURI() public view returns (string memory) {
    return nftContractMetadataUri;
  }
  
  event UpdatedContractURI(string _from, string _to);
  function updateContractURI(string memory uri) public onlyOwner {
    emit UpdatedContractURI(nftContractMetadataUri, uri);
    nftContractMetadataUri = uri;
  }
  
  function getOwnerNFTCount(address _owner) public view returns (uint256) {
      return NFTokenEnumerableMetadata._getOwnerNFTCount(_owner);
  }
  
  function updateTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    public
    validNFToken(_tokenId)
    onlyOwner
  {
    idToUri[_tokenId] = _uri;
  }
  
  

}

/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

//  SPDX-License-Identifier: MIT

/*
   _____             __ _                       _     _      
  / ____|           / _(_)                     | |   | |     v2 -> Matic Compatible
 | |     ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |__ | | ___ 
 | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | '_ \| |/ _ \
 | |___| (_) | | | | | | | (_| | |_| | | | (_| | |_) | |  __/
  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|_.__/|_|\___|
                           __/ |                             
  ______ _____   _____ ___|___/_                             
 |  ____|  __ \ / ____|__ \ / _ \                            
 | |__  | |__) | |       ) | | | |                           
 |  __| |  _  /| |      / /| | | |                           
 | |____| | \ \| |____ / /_| |_| |                           
 |______|_|  \_\\_____|____|\___/ 
 
 By the team that brought you:
  --- > Circuits of Value (http://circuitsofvalue.com)
  --- > Emblem Vault (https://emblem.finance)
  
 Documentation:
  --- > Github (https://github.com/EmblemLabs/ConfigurableERC20)
  
 UI:
  --- > (https://emblemlabs.github.io/ConfigurableERC20/)
*/

pragma solidity 0.8.4;
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./HasRegistration.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract ERC20Detailed is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool initialized;

    function init(string memory _name, string memory _symbol, uint8 _decimals) public {
        require(!initialized, "Already Initialized");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract Configurable is HasRegistration {
    using SafeMath for uint256;

    address private governance;
    bool internal _transferable = true;
    bool internal _burnable = true;
    bool internal _visible = true;
    bool internal _allowPrivateTransactions = false;
    bool internal _locked = false;
    bool internal _forever = false;
    uint256 internal _lockBlock = 0;

    mapping(address => bool) public minters;
    mapping(address => bool) public viewers;
    mapping(address => bool) public depositers;

    function _isGoverner() internal view returns (bool) {
        return _msgSender() == governance;
    }

    function _isViewer() internal view returns (bool) {
        return viewers[_msgSender()];
    }

    function _isMinter() internal view returns (bool) {
        return minters[_msgSender()];
    }
    
    function _isDepositer() internal view returns (bool) {
        return depositers[_msgSender()];
    }


    function transferable() public view returns (bool) {
        return _transferable;
    }

    function burnable() public view returns (bool) {
        return _burnable;
    }

    function visible() public view returns (bool) {
        return _visible;
    }

    function visibleOrAdmin() public view returns (bool) {
        return _visible || _isGoverner();
    }

    function allowPrivateTransactions() public view returns (bool) {
        return _allowPrivateTransactions;
    }

    function blockNumberLocked() public view returns (bool) {
        return _lockBlock != 0 && block.number < _lockBlock;
    }

    function locked() public view returns (bool) {
        return _locked || blockNumberLocked();
    }

    function lockedPermenantly() public view returns (bool) {
        return locked() && _forever;
    }

    function blocksTillUnlock() public view returns (uint256) {
        if (_lockBlock > block.number) {
            return _lockBlock.sub(block.number);
        } else {
            return 0;
        }
    }

    modifier isTransferable() {
        require(_transferable, "Contract does not allow transfering");
        _;
    }

    modifier isBurnable() {
        require(_burnable, "Contract does not allow burning");
        _;
    }

    modifier isVisibleOrCanView() {
        require(
            _visible || _isViewer() || _isGoverner(),
            "Contract is private and you are not Governer or on viewers list"
        );
        _;
    }

    modifier canSendPrivateOrGoverner() {
        require(
            _allowPrivateTransactions || _isGoverner(),
            "Contract cannot send private transactions"
        );
        _;
    }

    modifier onlyOwner() override {
        require(_isGoverner(), "Sender is not Governer");
        _;
    }

    modifier notLocked() {
        require(!locked(), "Contract is locked to governance changes");
        _;
    }

    modifier canMint() {
        require(_isMinter(), "No Minting Privilages");
        _;
    }
    
    modifier canDeposit() {
        require(_isDepositer(), "No Depositing Privilages");
        _;
    }

    function unLock() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        require(locked(), "Contract not locked");
        _locked = false;
    }

    function lockForever() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        _locked = true;
        _forever = true;
    }

    function lockTemporarily() public onlyOwner notLocked {
        _locked = true;
    }

    function lockTemporarilyTillBlock(uint256 blockNumber)
        public
        onlyOwner
        notLocked
    {
        require(
            block.number < blockNumber,
            "Provided Block numbner is in the past"
        );
        _lockBlock = blockNumber;
    }

    function toggleBurnable() public onlyOwner notLocked {
        _burnable = !_burnable;
    }

    function toggleTransferable() public onlyOwner notLocked {
        _transferable = !_transferable;
    }

    function toggleVisibility() public onlyOwner notLocked {
        _visible = !_visible;
    }

    function togglePrivateTransferability() public onlyOwner notLocked {
        _allowPrivateTransactions = !_allowPrivateTransactions;
    }

    function setGovernance(address _governance) public onlyOwner notLocked {
        _setGovernance(_governance);
    }
    
    /* For compatibility with Ownable */
    function transferOwnership(address _governance) public override onlyOwner notLocked {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) internal {
        minters[governance] = false; // Remove old owner from minters list
        viewers[governance] = false; // Remove old owner from viewers list
        depositers[governance] = false; //Remove old owner from depositer list
        minters[_governance] = true; // Add new owner to minters list
        viewers[_governance] = true; // Add new owner to viewers list
        depositers[_governance] = true; //Add new owner from depositer list
        governance = _governance; // Set new owner
    }
}

contract ERC20 is IERC20, Configurable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply()
        public
        override
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        override
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override isTransferable returns (bool) {
        _transferFromPrivate(sender, recipient, amount, visible());
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
    
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
    
    function deposit(address user, bytes calldata depositData)
        external
        canDeposit
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    function _transferFromPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable returns (bool) {
        _transferPrivate(sender, recipient, amount, _private);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        isTransferable
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal isTransferable {
        _transferPrivate(sender, recipient, amount, !visible());
    }

    function _transferPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        if (!_private) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        if (visible()) {
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        if (visible()) {
            emit Transfer(account, address(0), amount);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        if (visible()) {
            emit Approval(owner, spender, amount);
        }
    }
}

contract ConfigurableERC20 is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    constructor() {
        init(_msgSender(), name, symbol, decimals);
    }

    function init(address _owner, string memory _name, string memory _symbol, uint8 _decimals) public {
        require(!initialized, "Already Initialized");
        ERC20Detailed.init(_name, _symbol, _decimals);      
        _setGovernance(_owner);
        Configurable._transferable = true;
        Configurable._burnable = true;
        Configurable._visible = true;
        Configurable._allowPrivateTransactions = false;
        Configurable._locked = false;
        Configurable._forever = false;
        Configurable._lockBlock = 0; 
        initialized = true;
    }

    function transfer(
        address to,
        uint256 amount,
        bool _private
    ) public isTransferable canSendPrivateOrGoverner {
        _transferPrivate(_msgSender(), to, amount, _private);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bool _private
    ) public isTransferable canSendPrivateOrGoverner {
        _transferPrivate(from, to, amount, _private);
    }

    function mint(address account, uint256 amount) public canMint notLocked {
        _mint(account, amount);
    }

    function burn(uint256 amount) public isBurnable {
        _burn(_msgSender(), amount);
    }

    function changeContractDetails(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public onlyOwner notLocked {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function addMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = false;
    }

    function addViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = true;
    }

    function removeViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = false;
    }
    
    function addDepositer(address _depositer) public onlyOwner notLocked {
        depositers[_depositer] = true;
    }

    function removeDepositer(address _depositer) public onlyOwner notLocked {
        depositers[_depositer] = false;
    }
}

// File: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155.sol";
import "./HasRegistration.sol";
import "./IHandlerCallback.sol";
import "./IsSerialized.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */

contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI, HasRegistration, IsSerialized {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    bool initialized = false;
    string private _uri;
    
    constructor () {
        init(_msgSender());
    }

    function init(address _owner) public {
        require(!initialized, "Already Initialized");
        owner = _owner;
        _registerInterface(0xd9b67a26); //_INTERFACE_ID_ERC1155
        _registerInterface(0x0e89341c); //_INTERFACE_ID_ERC1155_METADATA_URI
        _uri = "https://api.emblemvault.io/s:evmetadata/meta/";
        serialized = true;
        initialized = true;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) public override onlyOwner {
        _mint(_to, _tokenId, _amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) public override {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), 'Not Approved to burn');
        _burn(_from, _tokenId, _amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), 'Not Approved to burn');
        _burnBatch(account, ids, amounts);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(_tokenId)));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {            
                uint256 serialNumber = getFirstSerialByOwner(from, id);
                if (serialNumber != 0 ) {
                    transferSerial(serialNumber, from, to);
                }
            }
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            }
        }
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            // _balances[id][from] = _balances[id][from].sub(
            //     amount,
            //     "ERC1155: insufficient balance for transfer"
            // );
            // _balances[id][to] = _balances[id][to].add(amount);
            // if (registeredOfType[3][0] != address(0)) {
            //     IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            // }
            safeTransferFrom(from, to, id, amount, data);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {
                mintSerial(id, account);
            }            
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(_msgSender()).executeCallbacks(address(0), account, id, IHandlerCallback.CallbackType.MINT);
            }
        }
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            // _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
            _mint(to, ids[i], amounts[i], data);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        if (isSerialized()) {            
            uint256 serialNumber = getFirstSerialByOwner(account, id);
            if (serialNumber != 0 ) {
                transferSerial(serialNumber, account, address(0));
            }            
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _burn(account, ids[i], amounts[i]);
            // _balances[ids[i]][account] = _balances[ids[i]][account].sub(
            //     amounts[i],
            //     "ERC1155: burn amount exceeds balance"
            // );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

pragma solidity 0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

pragma solidity 0.8.4;
interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
    function tokenPayload(uint256 _tokenId) external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
    function setApprovalForAll( address _operator, bool _approved) external;
}

pragma solidity 0.8.4;
import "./Ownable.sol";

contract Storage is Ownable {

    address public latestVersion;
    
    address DEADADDRESS = 0x000000000000000000000000000000000000dEaD;
    address BURNADDRESS = 0x5D152dd902CC9198B97E5b6Cf5fc23a8e4330180;
    
    mapping(address => bytes32) LegacyClaims;
    mapping(address => bytes32) LegacyClaimsBy;
    mapping(address => mapping(uint => address)) Claims;
    mapping(address => uint256[]) ClaimsFor;
    address[] BurnAddresses;
    
    constructor() {
        BurnAddresses.push(DEADADDRESS);
        BurnAddresses.push(BURNADDRESS);
    }
    
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion, 'Not latest version');
        _;
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner || msg.sender == _newVersion, 'Only owner can upgrade');
        latestVersion = _newVersion;
    }
    
    function getDead() external view returns(address) {
        return DEADADDRESS;
    }
    
    function getBurnAddresses() external view returns (address[] memory){
        return BurnAddresses;
    }
    
    function getLegacyClaims(address nftAddress) external view returns(bytes32) {
        return LegacyClaims[nftAddress];
    }
    function getLegacyClaimsBy(address nftAddress) external view returns(bytes32) {
        return LegacyClaimsBy[nftAddress];
    }
    
    function getClaims(address nftAddress, uint tokenId) external view returns (address) {
        return Claims[nftAddress][tokenId];
    }
    
    function getClaimsFor(address _owner) external view returns (uint256[] memory) {
        return ClaimsFor[_owner];
    }

    /* ADD : Protected by only current version */
    
    function addToBurnAddresses(address burnAddress) external onlyLatestVersion() {
         BurnAddresses.push(burnAddress);
    }
    
    function addToLegacy(address nftAddress, bytes32 root) external onlyLatestVersion() {
        LegacyClaims[nftAddress] = root;
    }
    function addToLegacyClaimedBy(address nftAddress, bytes32 root) external onlyLatestVersion() {
        LegacyClaimsBy[nftAddress] = root;
    }
    
    function addToClaims(address nftAddress, uint tokenId, address _owner) external onlyLatestVersion() {
        Claims[nftAddress][tokenId] = _owner;
        ClaimsFor[_owner].push(tokenId);
    }
}

pragma solidity 0.8.4;
import "./Ownable.sol";

contract BalanceStorage is Ownable {
    
    address public latestVersion = address(0x0);
    mapping(uint256 => bool) public usedNonces;

    struct BalanceObject {
        uint balance;
        uint blockchain;
        string name;
        string symbol;
        uint256 tokenId;
        address _address;
        uint256 _type;
    }

    struct Balances {
        BalanceObject[] balances;
    }

    mapping(address => mapping(uint256 => Balances)) internal balances;
    mapping(address => uint256[]) contractTokenIds;
    mapping(address=> mapping(address => bool)) public witnesses;
    mapping(bytes32 => mapping(address => uint256[])) public tokensToContractMap;

    constructor() {
        
    }
    
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion || msg.sender == owner, 'Not Owner or Latest version');
        _;
    }

    function addWitness(address nftAddress, address _witness) public onlyLatestVersion {
        witnesses[nftAddress][_witness] = true;
    }

    function removeWitness(address nftAddress, address _witness) public onlyLatestVersion {
        witnesses[nftAddress][_witness] = false;
    }

    function isWitness(address nftAddress, address witness) public view onlyLatestVersion returns (bool) {
        return witnesses[nftAddress][witness];
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner || (msg.sender == _newVersion && latestVersion == address(0x0) || msg.sender == latestVersion), 'Only owner can upgrade');
        latestVersion = _newVersion;
    }

    function getBalance(address nftAddress, uint256 tokenId) public view onlyLatestVersion returns (Balances memory) {
        return balances[nftAddress][tokenId];
    } 

    function getAssetsForContract(address nftAddress) public view onlyLatestVersion returns (uint256[] memory) {
        return contractTokenIds[nftAddress];
    }

    function getAssetsForContractAtIndex(address nftAddress, uint256 index) public view onlyLatestVersion returns (uint256) {
        return contractTokenIds[nftAddress][index];
    }

    function usedNonce(uint256 nonce) public view onlyLatestVersion returns (bool) {
        return usedNonces[nonce];
    }

    function getTokensFromMap(address nftAddress, bytes32 token) public view onlyLatestVersion returns(uint256[] memory) {
        return tokensToContractMap[token][nftAddress];
    }

    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance) public onlyLatestVersion {
         balances[nftAddress][tokenId] = balance;
         contractTokenIds[nftAddress].push(tokenId);
    }

    function addTokenToMap(address nftAddress, bytes32 token, uint256 tokenId) public onlyLatestVersion {
        tokensToContractMap[token][nftAddress].push(tokenId);
    }

    function addNonce(uint256 nonce) public onlyLatestVersion returns (bool) {
        require(!usedNonces[nonce], 'Nonce already used');
        return usedNonces[nonce] = true;
    }
    
}

pragma solidity 0.8.4;
import "./IERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./HasRegistration.sol";

interface IStorage {
    function getDead() external view returns(address);
    function addToLegacy(address nftAddress, bytes32 root) external;
    function addToLegacyClaimedBy(address nftAddress, bytes32 root) external;
    function getLegacyClaims(address nftAddress) external view returns (bytes32);
    function getLegacyClaimsBy(address nftAddress) external view returns (bytes32);
    function addToClaims(address nftAddress, uint tokenId, address _owner) external;
    function getClaims(address nftAddress, uint tokenId) external view returns (address);
    function getClaimsFor(address _owner) external view returns (uint256[] memory);
    function getBurnAddresses() external view returns (address[] memory);
    function addToBurnAddresses(address burnAddress) external;
    function upgradeVersion(address _newVersion) external;
}

contract Claimed is ReentrancyGuard, HasRegistration {
    
    address StorageAddress;
    bool initialized = false;
    bool canClaim = true;
    
    constructor(address storageContract) {
        StorageAddress = storageContract;
        initialize();
    }
    
    function initialize() public {
        require(!initialized, 'already initialized');
        IStorage _storage = IStorage(StorageAddress);
        _storage.upgradeVersion(address(this));
        initialized = true;
    }
    
    function isBurnAddress(address needle) public view returns (bool) {
        address[] memory BurnAddresses = IStorage(StorageAddress).getBurnAddresses();
        for (uint i=0; i < BurnAddresses.length; i++) {
            if (BurnAddresses[i] == needle) {
                return true;
            }
        }
        return false;
    }

    function toggleCanClaim() public onlyOwner {
        canClaim = !canClaim;
    }
    
    function claim(address nftAddress, uint tokenId, address _claimedBy) public nonReentrant isRegisteredContract(_msgSender()) {        
        if (canClaim) {
            IStorage(StorageAddress).addToClaims(nftAddress, tokenId, _claimedBy);
        } else { 
            revert("Claiming is turned off");
        }
    }
    
    function isClaimed(address nftAddress, uint tokenId, bytes32[] calldata proof ) public view returns(bool) {
        bytes32 _hash = keccak256(abi.encodePacked(tokenId));
        IERC721 token = IERC721(nftAddress);        
        if (proof.length == 0) {
            bool claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId) != address(0);
            bool addressClaimed = false;
            try token.ownerOf(tokenId) returns (address _owner) {
                if (isBurnAddress(_owner)) {
                    addressClaimed = true;
                }
            } catch {}
            return addressClaimed || claimed;
        } else {
            bytes32 root = IStorage(StorageAddress).getLegacyClaims(nftAddress);
            return verifyScript(root, _hash, proof);
        }
    }

    function getClaimsFor(address _owner) public view returns (uint256[] memory) {
        return IStorage(StorageAddress).getClaimsFor(_owner);
    }

    function getLegacyClaims(address nftAddress) external view returns(bytes32) {
        return IStorage(StorageAddress).getLegacyClaims(nftAddress);
    }
    
    function claimedBy(address nftAddress, uint tokenId) public view returns (address _owner, string memory _type) {
        address claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId);
        if (claimed != address(0)) {
            return (claimed, "record");
        } else {
            return (address(0), "unknown");
        }
    }

    function legacyClaimedBy(address nftAddress, address claimant, uint tokenId, bytes32[] calldata proof) public view returns (address _owner, string memory _type) {
        bytes32 root = IStorage(StorageAddress).getLegacyClaimsBy(nftAddress);
        bytes32 _hash = keccak256(abi.encodePacked(claimant, tokenId));
        require(verifyScript(root, _hash, proof), "invalid proof");
        return (claimant, 'legacy');
    }

    function addLegacy(address nftAddress, bytes32 root) onlyOwner public {
        IStorage(StorageAddress).addToLegacy(nftAddress, root);        
    }

    function addLegacyClaimedBy(address nftAddress, bytes32 root) onlyOwner public {
        IStorage(StorageAddress).addToLegacyClaimedBy(nftAddress, root);        
    }

    function verifyScript(bytes32 root, bytes32 _hash, bytes32[] calldata proof) public pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (_hash <= proofElement) {
                _hash = optihash(_hash, proofElement);
            } else {
                _hash = optihash(proofElement, _hash);
            }
        }
        return _hash == root;
    }
    // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
    function optihash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
        mstore(0x00, a)
        mstore(0x20, b)
        value := keccak256(0x00, 0x40)
        }
    }

}

pragma solidity 0.8.4;
import "./IERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./HasRegistration.sol";

struct BalanceObject {
    uint balance;
    uint blockchain;
    string name;
    string symbol;
    uint256 tokenId;
    address _address;
    uint256 _type;
}

struct Balances {
    BalanceObject[] balances;
}

interface IBalanceStorage {
    function upgradeVersion(address _newVersion) external;
    function getBalance(address nftAddress, uint256 tokenId) external view returns (Balances calldata balance);
    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance) external;
    function addWitness(address nftAddress, address _witness) external;
    function removeWitness(address nftAddress, address _witness) external;
    function isWitness(address nftAddress, address witness) external view returns (bool);
    function usedNonce(uint256 nonce) external view returns (bool);
    function addNonce(uint256 nonce) external returns (bool);
    function getAssetsForContract(address nftAddress) external view returns (uint256[] memory);
    function getAssetsForContractAtIndex(address nftAddress, uint256 index) external view returns (uint256);
    function addTokenToMap(address nftAddress, bytes32 token, uint256 tokenId) external;
    function getTokensFromMap(address nftAddress, bytes32 token) external view returns (uint256[] memory);
}

contract Balance is ReentrancyGuard, HasRegistration {

    address StorageAddress;
    bool initialized = false;
    bool canAddBalances = true;
    
    constructor(address storageContract) {
        StorageAddress = storageContract;
        initialize();
    }
    
    function initialize() internal {
        require(!initialized, 'already initialized');
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        _storage.upgradeVersion(address(this));
        initialized = true;
    }

    /* ADMIN WRITE */
    function addWitness(address nftAddress, address witness) external onlyOwner {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.addWitness(nftAddress, witness);
    }

    function removeWitness(address nftAddress, address witness) external onlyOwner {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.removeWitness(nftAddress, witness);
    }

    function promoteVersion(address balanceContract) external onlyOwner {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        _storage.upgradeVersion(balanceContract);
    }

    function toggleCanAddBalances() public onlyOwner {
        canAddBalances = !canAddBalances;
    }

    /* USER WRITE */

    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance, uint256 nonce, bytes calldata signature) public nonReentrant {
        if (canAddBalances) {
            IBalanceStorage _storage = IBalanceStorage(StorageAddress);
            require(IERC721(nftAddress).ownerOf(tokenId) == _msgSender(), 'Only owner can add balance');
            require(!_storage.usedNonce(nonce), 'Nonce already used');
            require(_storage.addNonce(nonce), 'Nonce not added');
            bytes32 serializedBalance = getSerializedBalance(balance);
            bytes32 _hash = addNonceToSerializedBalance(serializedBalance, nonce);
            require(isWitnessed(nftAddress, _hash, signature), 'Not a witness');
            _storage.addBalanceToAsset(nftAddress, tokenId, balance);
            addTokensToMap(nftAddress, tokenId, balance);
        } else {
            revert("Adding balances is disabled");
        }
        
    }

    function addTokensToMap(address nftAddress, uint256 tokenId, Balances calldata balances) internal {
        for (uint i = 0; i < balances.balances.length; i++) {
            BalanceObject memory balance = balances.balances[i];
            bytes32 _hash = keccak256(abi.encodePacked(balance.blockchain, balance.name));
            IBalanceStorage _storage = IBalanceStorage(StorageAddress);
            _storage.addTokenToMap(nftAddress, _hash, tokenId);
        }
    }

    /* READ */
    function getBalance(address nftAddress, uint256 tokenId) external view returns (Balances memory balance) {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getBalance(nftAddress, tokenId);
    }

    function getSerializedBalances(Balances calldata balances) public pure returns (bytes32[] memory) {
        bytes32[] memory hashes = new bytes32[](balances.balances.length);
        for (uint i = 0; i < balances.balances.length; i++) {
            BalanceObject memory balance = balances.balances[i];
            hashes[i] = keccak256(abi.encodePacked(balance.balance, balance.blockchain, balance.name, balance.symbol, balance.tokenId, balance._address, balance._type));
        }
        return hashes;
    }

    function getSerializedBalance(Balances calldata balances) public pure returns (bytes32) {
        bytes32[] memory hashes = getSerializedBalances(balances);
        bytes32 _hash = keccak256(abi.encodePacked(hashes[0]));
        for (uint i = 1; i < hashes.length; i++) {
            _hash = keccak256(abi.encodePacked(_hash, hashes[i]));
        }
        return _hash;
    }    

    function addNonceToSerializedBalance(bytes32 _hash, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nonce, _hash));
    }

    function isWitnessed(address nftAddress, bytes32 _hash, bytes calldata signature) public view returns (bool) {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        address addressFromSig = recoverSigner(_hash, signature);
        return _storage.isWitness(nftAddress, addressFromSig);
    }    

    function getAssetsForContract(address nftAddress) external view returns (uint256[] memory) {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getAssetsForContract(nftAddress);
    }

    function getAssetCountForContract(address nftAddress) external view returns (uint256) {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getAssetsForContract(nftAddress).length;
    }

    function getAssetsForContractAtIndex(address nftAddress, uint256 index) external view returns (uint256) {
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getAssetsForContractAtIndex(nftAddress, index);
    }

    function getTokenIdsFromMap(address nftAddress, uint blockchain, string calldata name) public view returns (uint256[] memory) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getTokensFromMap(nftAddress, _hash);
    }

    function getTokenIdCountFromMap(address nftAddress, uint blockchain, string calldata name) public view returns(uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getTokensFromMap(nftAddress, _hash).length;
    }

    function getTokenIdsFromMapAtIndex(address nftAddress, uint blockchain, string calldata name, uint256 index) public view returns (uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockchain, name));
        IBalanceStorage _storage = IBalanceStorage(StorageAddress);
        return _storage.getTokensFromMap(nftAddress, _hash)[index];
    }

    /* UTIL */
    function getAddressFromSignatureHash(bytes32 _hash, bytes calldata signature) public pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }

    function recoverSigner(bytes32 hash, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.8.4;
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./BasicERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";

contract NFTrade_v2 is Context, Ownable, ReentrancyGuard {
    
    address resolver;
    bool public initialized;
    address public paymentAddress = address(this);
    address public recipientAddress;
    uint256 public makeOfferPrice = 0;
    uint256 public acceptOfferPrice = 0;
    uint public percentageFee = 0;
    bool public payToAcceptOffer = false;
    bool public payToMakeOffer = false;
    bool public canOfferERC20 = false;
    bool public takePercentageOfERC20 = false;
    bool public locked = false;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    using SafeMath for uint;

    struct Offer {
        uint tokenId;
        address _from;
        address token;
        uint amount;
    }
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    mapping(address => mapping(uint => Offer[])) offers;
    mapping(address => mapping(uint => Offer[])) rejected;
    mapping(address => mapping(address => mapping(uint => Offer[]))) offered;
    mapping(address => mapping(uint => Offer[])) accepted;
    
    modifier notLocked() {
        require(!locked, "Contract is locked");
        _;
    }
    
    constructor(address _paymentAddress, address _recipientAddress) {
        init(_paymentAddress, _recipientAddress);
    }
    
    function init(address _paymentAddress, address _recipientAddress) public {
        require(!initialized, 'Already initialized');
        initialized = true;
        owner = payable(msg.sender); // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        paymentAddress = _paymentAddress;
        recipientAddress = _recipientAddress;
    }
    
    function getVersion() public pure returns (uint) {
        return 1;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    event OfferAccepted(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 _amount);
    function acceptOffer(address token, uint _tokenId, uint index) public notLocked nonReentrant {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken1 = IERC721(token);
        IERC721 nftToken2 = IERC721(_offer.token);

        require(!checkInterface(token, _INTERFACE_ID_ERC20), 'not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'Sender is not owner of NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');
        }

        require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');

        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            require(IERC20Token(_offer.token).balanceOf(_offer._from) >= _offer.amount, 'Not Enough Offer Balance');
            require(IERC20Token(_offer.token).allowance(_offer._from, address(this)) >= _offer.amount, 'Not Enough Offer Allowance');
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            require(nftToken2.balanceOf(_offer._from, _offer.tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        } else {
            require(nftToken2.ownerOf(_offer.tokenId) == _offer._from, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        }        
        if (acceptOfferPrice > 0 && payToAcceptOffer) {
            IERC20Token paymentToken = IERC20Token(paymentAddress);
            require(paymentToken.allowance(msg.sender, address(this)) >= acceptOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= acceptOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), acceptOfferPrice), 'Payment error');
        }
        
        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            if (takePercentageOfERC20 && percentageFee > 0) {
                uint fee = fromPercent(_offer.amount, percentageFee);
                uint value = _offer.amount.sub(fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, address(recipientAddress), fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, value);
            } else {
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, _offer.amount);
            }
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            IERC1155(_offer.token).safeTransferFrom(_offer._from, msg.sender, _offer.tokenId, _offer.amount, "");
        } else {
            nftToken2.safeTransferFrom(_offer._from, msg.sender, _offer.tokenId);
        }

        if (checkInterface(token, _INTERFACE_ID_ERC20)) {
            // IERC20Token(token).transferFrom(msg.sender,  _offer._from, _offer.amount);
            revert('not allowed to make offers for erc20');
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            IERC1155(token).safeTransferFrom(msg.sender, _offer._from, _tokenId, _offer.amount, "");
        } else {
            nftToken1.safeTransferFrom(msg.sender, _offer._from, _tokenId);
        }
        
        delete offers[token][_tokenId];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
        accepted[token][_tokenId].push(_offer);
        emit OfferAccepted(_offer.token, _offer.tokenId, token, _tokenId, _offer.amount);
    }
    
    event OfferAdded(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount);
    function addOffer(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount) public notLocked nonReentrant {
        IERC721 nftToken1 = IERC721(token);
        IERC20Token paymentToken = IERC20Token(paymentAddress);

        // require(!checkInterface(_forNft, _INTERFACE_ID_ERC20), 'Not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC20) && canOfferERC20) {            
            require(IERC20Token(token).balanceOf(msg.sender) >= amount, 'Not Enough Balance');
            require(IERC20Token(token).allowance(msg.sender, address(this)) >= amount, 'Not Enough Allowance');
        } else if(checkInterface(token, _INTERFACE_ID_ERC20) && !canOfferERC20) {
            revert("Not allowed to make offers of erc20");
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender, 'Sender not owner of NFT');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        }

        if (makeOfferPrice > 0 && payToMakeOffer) {
            require(paymentToken.allowance(msg.sender, address(this)) >= makeOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= makeOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), makeOfferPrice), 'Payment error');
        }
        offers[_forNft][_for].push(Offer(_tokenId, msg.sender, token, amount));
        offered[token][msg.sender][_tokenId].push(Offer(_for, msg.sender, _forNft, amount));
        emit OfferAdded(token, _tokenId, _forNft, _for, amount);
    }
    
    function rejectOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken = IERC721(token);

        require(nftToken.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');

        rejected[token][_tokenId].push(_offer);
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function withdrawOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        
        require(_offer._from == msg.sender, 'Not senders offer to withdraw');
        
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function togglePayToMakeOffer() public onlyOwner {
        payToMakeOffer = !payToMakeOffer;
    }
    function togglePayToAcceptOffer() public onlyOwner {
        payToAcceptOffer = !payToAcceptOffer;
    }
    
    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    function toggleCanOfferERC20() public onlyOwner {
        canOfferERC20 = !canOfferERC20;
    }

    function toggleTakePercentageOfERC20() public onlyOwner {
        takePercentageOfERC20 = !takePercentageOfERC20;
    }
    
    function getOffer(address token, uint256 _tokenId, uint index) public view returns (Offer memory) {
        return offers[token][_tokenId][index];
    }
    
    function getOffered(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return offered[token][msg.sender][_tokenId];
    }
    
    function getOfferCount(address token, uint256 _tokenId) public view returns (uint) {
        return offers[token][_tokenId].length;
    }
    
    function getAcceptedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return accepted[token][_tokenId];
    }
    
    function getRejectedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return rejected[token][_tokenId];
    }
    
    function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee) public onlyOwner {
        makeOfferPrice = _makeOfferPrice;
        acceptOfferPrice = _acceptOfferPrice;
        percentageFee = _percentageFee;
    }
    
    function changeRecipientAddress(address _recipientAddress) public onlyOwner {
       recipientAddress = _recipientAddress;
    }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    function fromPercent(uint total, uint percent) public pure returns (uint) {
        return total.mul(percent).div(100);
    }

    function toPercent(uint amount, uint total) public pure returns (uint) {
        return amount.mul(100).div(total);
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./BasicERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";



contract NFTrade_v3 is Context, Ownable, ReentrancyGuard {
    
    address resolver;
    bool public initialized;
    bool public locked = false;
    
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    using SafeMath for uint;

    struct Offer {
        uint tokenId;
        address _from;
        address token;
        uint amount;
    }
    
    struct Config {
        address recipientAddress;
        address paymentAddress;
        uint256 makeOfferPrice;
        uint256 acceptOfferPrice;
        uint percentageFee;
        bool payToAcceptOffer;
        bool payToMakeOffer;
        bool canOfferERC20;
        bool takePercentageOfERC20;
        bool Active;
        bytes32 Parent;
        uint ParentPercentage;
    }
    
    // event for EVM logging
    mapping(uint256 => Config) configs;
    mapping(address => mapping(uint => Offer[])) offers;
    mapping(address => mapping(uint => Offer[])) rejected;
    mapping(address => mapping(address => mapping(uint => Offer[]))) offered;
    mapping(address => mapping(uint => Offer[])) accepted;
    
    modifier notLocked() {
        require(!locked, "Contract is locked");
        _;
    }
    
    constructor(address _paymentAddress, address _recipientAddress) {
        init(_paymentAddress, _recipientAddress);
    }
    
    function init(address _paymentAddress, address _recipientAddress) public {
        require(!initialized, 'Already initialized');
        initialized = true;
        configs[1337] = Config(_recipientAddress, _paymentAddress, 0, 0, 0, false, false, false, false, true, 0, 0);
    }
    
    function getVersion() public pure returns (uint) {
        return 1;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    event OfferAccepted(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 _amount);
    function acceptOffer(address token, uint _tokenId, uint index, uint apikey) public notLocked nonReentrant {
        Config memory _config = configs[apikey];
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken1 = IERC721(token);
        IERC721 nftToken2 = IERC721(_offer.token);

        require(!checkInterface(token, _INTERFACE_ID_ERC20), 'not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'Sender is not owner of NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');
        }

        require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');

        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            require(IERC20Token(_offer.token).balanceOf(_offer._from) >= _offer.amount, 'Not Enough Offer Balance');
            require(IERC20Token(_offer.token).allowance(_offer._from, address(this)) >= _offer.amount, 'Not Enough Offer Allowance');
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            require(nftToken2.balanceOf(_offer._from, _offer.tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        } else {
            require(nftToken2.ownerOf(_offer.tokenId) == _offer._from, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        }        
        if (_config.acceptOfferPrice > 0 && _config.payToAcceptOffer) {
            IERC20Token paymentToken = IERC20Token(_config.paymentAddress);
            require(paymentToken.allowance(msg.sender, address(this)) >= _config.acceptOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= _config.acceptOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(_config.recipientAddress), _config.acceptOfferPrice), 'Payment error');
        }
        
        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            if (_config.takePercentageOfERC20 && _config.percentageFee > 0) {
                uint fee = fromPercent(_offer.amount, _config.percentageFee);
                uint value = _offer.amount.sub(fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, address(_config.recipientAddress), fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, value);
            } else {
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, _offer.amount);
            }
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            IERC1155(_offer.token).safeTransferFrom(_offer._from, msg.sender, _offer.tokenId, _offer.amount, "");
        } else {
            nftToken2.safeTransferFrom(_offer._from, msg.sender, _offer.tokenId);
        }

        if (checkInterface(token, _INTERFACE_ID_ERC20)) {
            // IERC20Token(token).transferFrom(msg.sender,  _offer._from, _offer.amount);
            revert('not allowed to make offers for erc20');
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            IERC1155(token).safeTransferFrom(msg.sender, _offer._from, _tokenId, _offer.amount, "");
        } else {
            nftToken1.safeTransferFrom(msg.sender, _offer._from, _tokenId);
        }
        
        delete offers[token][_tokenId];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
        accepted[token][_tokenId].push(_offer);
        emit OfferAccepted(_offer.token, _offer.tokenId, token, _tokenId, _offer.amount);
    }
    
    event OfferAdded(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount);
    function addOffer(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount, uint256 apikey) public notLocked nonReentrant {
        Config memory _config = configs[apikey];
        IERC721 nftToken1 = IERC721(token);
        IERC20Token paymentToken = IERC20Token(_config.paymentAddress);

        // require(!checkInterface(_forNft, _INTERFACE_ID_ERC20), 'Not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC20) && _config.canOfferERC20) {
            require(IERC20Token(token).balanceOf(msg.sender) >= amount, 'Not Enough Balance');
            require(IERC20Token(token).allowance(msg.sender, address(this)) >= amount, 'Not Enough Allowance');
        } else if(checkInterface(token, _INTERFACE_ID_ERC20) && !_config.canOfferERC20) {
            revert("Not allowed to make offers of erc20");
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender, 'Sender not owner of NFT');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        }

        if (_config.makeOfferPrice > 0 && _config.payToMakeOffer) {
            require(paymentToken.allowance(msg.sender, address(this)) >= _config.makeOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= _config.makeOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(_config.recipientAddress), _config.makeOfferPrice), 'Payment error');
        }
        offers[_forNft][_for].push(Offer(_tokenId, msg.sender, token, amount));
        offered[token][msg.sender][_tokenId].push(Offer(_for, msg.sender, _forNft, amount));
        emit OfferAdded(token, _tokenId, _forNft, _for, amount);
    }
    
    function rejectOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken = IERC721(token);

        require(nftToken.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');

        rejected[token][_tokenId].push(_offer);
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function withdrawOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        
        require(_offer._from == msg.sender, 'Not senders offer to withdraw');
        
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    // function togglePayToMakeOffer() public onlyOwner {
    //     togglePayToMakeOffer(1337);
    // }
    
    function togglePayToMakeOffer(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.payToMakeOffer = !_config.payToMakeOffer;
    }
    
    // function togglePayToAcceptOffer() public onlyOwner {
    //     togglePayToAcceptOffer(1337);
    // }
    
    function togglePayToAcceptOffer(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.payToAcceptOffer = !_config.payToAcceptOffer;
    }
    
    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    // function toggleCanOfferERC20() public onlyOwner {
    //     toggleCanOfferERC20(1337);
    // }
    
    function toggleCanOfferERC20(uint256 apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.canOfferERC20 = !_config.canOfferERC20;
    }

    // function toggleTakePercentageOfERC20() public onlyOwner {
    //     toggleTakePercentageOfERC20(1337);
    // }
    
    function toggleTakePercentageOfERC20(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.takePercentageOfERC20 = !_config.takePercentageOfERC20;
    }
    
    function getOffer(address token, uint256 _tokenId, uint index) public view returns (Offer memory) {
        return offers[token][_tokenId][index];
    }

    function getConfig(uint256 apikey) public view returns (Config memory) {
        return configs[apikey]; 
    }
    
    function getOffered(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return offered[token][msg.sender][_tokenId];
    }
    
    function getOfferCount(address token, uint256 _tokenId) public view returns (uint) {
        return offers[token][_tokenId].length;
    }
    
    function getAcceptedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return accepted[token][_tokenId];
    }
    
    function getRejectedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return rejected[token][_tokenId];
    }
    
    // function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee) public onlyOwner {
    //     changeOfferPrices(_makeOfferPrice, _acceptOfferPrice, _percentageFee, 1337);
    // }
    function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee, uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.makeOfferPrice = _makeOfferPrice;
        _config.acceptOfferPrice = _acceptOfferPrice;
        _config.percentageFee = _percentageFee;
    }
    
    // function changeRecipientAddress(address _recipientAddress) public onlyOwner {
    //     changeRecipientAddress(_recipientAddress, 1337);
    // }
    
    function changeRecipientAddress(address _recipientAddress, uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.recipientAddress = _recipientAddress;
    }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    function fromPercent(uint total, uint percent) public pure returns (uint) {
        return total.mul(percent).div(100);
    }

    function toPercent(uint amount, uint total) public pure returns (uint) {
        return amount.mul(100).div(total);
    }
}

pragma solidity 0.8.4;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.8.4;
/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() virtual
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    virtual
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

pragma solidity 0.8.4;
import "./HasRegistration.sol";
import "./IHandlerCallback.sol";
import "./ERC165.sol";

contract HasCallbacks is HasRegistration {

    bool allowCallbacks = true;
    
    event CallbackExecuted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type, bytes returnData);
    event CallbackReverted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    event CallbackFailed(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    
    mapping(address => mapping(uint256 => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[]))) public registeredCallbacks;
    mapping(address => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[])) public registeredWildcardCallbacks;    

    modifier isOwnerOrCallbackRegistrant(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) {
        bool registrant = false;
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            registrant = registeredCallbacks[_contract][tokenId][_type][index].registrant == _msgSender();
        } else if(hasWildcardCallback(_contract, target, _type)) {
           registrant = registeredWildcardCallbacks[_contract][_type][index].registrant == _msgSender();
        }        
        require(_msgSender() == owner || registrant, "Not owner or Callback registrant");
        _;
    }

    function executeCallbacks(address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) public isRegisteredContract(_msgSender()) {
        if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_msgSender()][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_msgSender()][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
        }        
    }

    function executeCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal isRegisteredContract(_nftAddress) {
         if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_nftAddress][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_nftAddress][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
         }
    }

    function executeCallbackLoop(IHandlerCallback.Callback[] memory callbacks, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal {
        bool canRevert = false;  
        for (uint256 i = 0; i < callbacks.length; ++i) {            
            IHandlerCallback.Callback memory cb = callbacks[i];    
            canRevert = cb.canRevert;
            if (cb.target != address(0)){
                (bool success, bytes memory returnData) =
                    address(cb.target).call(
                        abi.encodePacked(
                            cb.targetFunction,
                            abi.encode(_from),
                            abi.encode(_to),
                            abi.encode(tokenId)
                        )
                    );
                if (success) {
                    emit CallbackExecuted(_from, _to, cb.target, tokenId, cb.targetFunction, _type, returnData);
                } else if (canRevert) {
                    emit CallbackReverted(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                    revert("Callback Reverted");
                } else {
                    emit CallbackFailed(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                }
            }
        }
    }

    function toggleAllowCallbacks() public onlyOwner {
        allowCallbacks = !allowCallbacks;
    }

    function registerCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredCallbacks[_contract][tokenId][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function registerWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredWildcardCallbacks[_contract][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function hasCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) public view returns (bool ) {
        bool found = hasTokenIdCallback(_contract, target, tokenId, _type);
        if (found) return true;
        return hasWildcardCallback(_contract, target, _type);
    }

    function hasTokenIdCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_contract][tokenId][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function hasWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredWildcardCallbacks[_contract][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function unregisterCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) public isOwnerOrCallbackRegistrant(_contract, target, tokenId, _type, index){
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            delete registeredCallbacks[_contract][tokenId][_type][index];
        }
        else if(hasWildcardCallback(_contract, target, _type)) {
            delete registeredWildcardCallbacks[_contract][_type][index];
        }
    }

    uint256 public ticks = 0;
    uint256 public lastTokenId = 0;
    address public lastTo;
    address public lastFrom;
    address public lastContract;

    function testCallback(address _from, address _to, uint256 tokenId) public {
        ticks++;
        lastTokenId = tokenId;
        lastTo = _to;
        lastFrom = _from;  
        lastContract = _msgSender();
    }

    function testRevertCallback(address _from, address _to, uint256 tokenId) public pure {
        _from = address(0);
        _to = address(0);
        tokenId = 0;
        revert("reverted by design");
    }

    function getTestSelector() public view returns (bytes4) {
        return HasCallbacks(this).testCallback.selector;
    }

    function getTestRevertSelector() public view returns (bytes4) {
        return HasCallbacks(this).testRevertCallback.selector;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./HasRegistration.sol";

contract TokenStaking is Ownable, HasRegistration {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;       // How many staking tokens the user has provided.
        uint256 rewardDebt;   // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken;
        uint256 perBlockTokenAllocated;
        uint256 lastRewardBlock;
        uint256 accPerShare;
    }

    IERC20 public tokenContract;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public startBlock;
    bool initialized;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ContractFunded(address indexed from, uint256 amount);

    constructor() {
        init(_msgSender(), IERC20(address(0)) ,block.number);
    }

    function init(address _owner, IERC20 _tokenContract, uint256 _startBlock) public {
        require(!initialized, "Already Initialized");
        owner = _owner;
        tokenContract = _tokenContract;
        startBlock = _startBlock;
        initialized = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _tokenPerBlock, IERC20 _stakingToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            stakingToken: _stakingToken,
            perBlockTokenAllocated: _tokenPerBlock,
            lastRewardBlock: lastRewardBlock,
            accPerShare: 0
        }));
    }

    function set(uint256 _poolId, uint256 _tokenPerBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo[_poolId].perBlockTokenAllocated = _tokenPerBlock;
    }

    function fund(uint256 _amount) public {
        address _from = address(msg.sender);
        require(_from != address(0), 'fund: must pass valid _from address');
        require(_amount > 0, 'fund: expecting a positive non zero _amount value');
        require(tokenContract.balanceOf(_from) >= _amount, 'fund: expected an address that contains enough Token for Transfer');
        tokenContract.transferFrom(_from, address(this), _amount);
        emit ContractFunded(_from, _amount);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingReward(uint256 _poolId, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 tokenSupply = pool.stakingToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(pool.perBlockTokenAllocated);
            accPerShare = accPerShare.add(reward.mul(1e12).div(tokenSupply));
        }
        return user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
    }

    function harvest(uint256 _poolId) external returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        updatePool(0);
        console.log('currentBlock', block.number, pool.accPerShare);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            safeTokenTransfer(msg.sender, pending);
            return pending;
        }
        return 0;
    }

    function getLockedView() external view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function getStakingTokenSupply(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        return pool.stakingToken.balanceOf(address(this));
    }

    //////////////////
    //
    // PUBLIC functions
    //
    //////////////////


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update pool supply and reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply = pool.stakingToken.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(pool.perBlockTokenAllocated);
        pool.accPerShare = pool.accPerShare.add(reward.mul(1e12).div(tokenSupply));

        pool.lastRewardBlock = block.number;
    }

    // Deposit staking tokens to Contract for Token allocation.
    function deposit(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        updatePool(_poolId);
        // if user already has staking tokens in the pool execute harvest for the user
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeTokenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);

        emit Deposit(msg.sender, _poolId, _amount);
    }

    // Withdraw staking tokens from Contract.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);

        if(pending > 0) {
            safeTokenTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.stakingToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    //////////////////
    //
    // INTERNAL functions
    //
    //////////////////

    // Safe Token transfer function, just in case if rounding error causes pool to not have enough Token.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        address _from = address(this);
        uint256 bal = tokenContract.balanceOf(_from);
        if (_amount > bal) {
            tokenContract.transfer(_to, bal);
        } else {
            tokenContract.transfer(_to, _amount);
        }
    }
}

pragma solidity 0.8.4;
// import "./IERC1155.sol";
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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}

// File: IERC1155Receiver.sol



/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI  {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

pragma solidity 0.8.4;
import "./Context.sol";
import "./Ownable.sol";

interface IRegistrationStorage {
    function upgradeVersion(address _newVersion) external;
}

contract HasRegistration is Context, Ownable {

    // address StorageAddress;
    // bool initialized = false;

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING
    mapping(uint256 => address[]) public registeredOfType;
    
    uint256 public contractCount = 0;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    // constructor(address storageContract) {
    //     StorageAddress = storageContract;
    // }

    // function initialize() public {
    //     require(!initialized, 'already initialized');
    //     IRegistrationStorage _storage = IRegistrationStorage(StorageAddress);
    //     _storage.upgradeVersion(address(this));
    //     initialized = true;
    // }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        contractCount++;
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        require(contractCount > 0, 'No vault contracts to remove');
        delete registeredOfType[registeredContracts[_contract]][index];
        delete registeredContracts[_contract];
        contractCount--;
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }
}

pragma solidity 0.8.4;
contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}

pragma solidity 0.8.4;

interface IHandlerCallback {
    enum CallbackType {
        MINT, TRANSFER, CLAIM
    }

    struct Callback {
        address vault;
        address registrant;
        address target;
        bytes4 targetFunction;
        bool canRevert;
    }
    function executeCallbacksInternal(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeCallbacks(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeStoredCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity 0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.4;
import "./ERC165.sol";
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
}

pragma solidity 0.8.4;
import "./Context.sol";
import "./Ownable.sol";

interface IIsSerialized {
    function isSerialized() external view returns (bool);
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256);
    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256);
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);
}

contract IsSerialized is Context, Ownable {
    bool internal serialized;
    bool internal hasSerialized = false;
    mapping(uint256 => uint256[]) internal tokenIdToSerials;
    mapping(uint256 => uint256) internal serialToTokenId;
    mapping(uint256 => address) internal serialToOwner;
    mapping(address => uint256) public ownerSerialCount;

    function isSerialized() public view returns (bool) {
        return serialized;
    }

    function toggleSerialization() public onlyOwner {
        require(!hasSerialized, "Already has serialized items");
        serialized = !serialized;
    }

    function mintSerial(uint256 tokenId, address owner) public onlyOwner {
        uint256 serialNumber = uint256(keccak256(abi.encode(tokenId, owner, ownerSerialCount[owner])));
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = owner;
        ownerSerialCount[owner]++;
        if (!hasSerialized) {
            hasSerialized = true;
        }
    }

    function transferSerial(uint256 serialNumber, address from, address to) internal {
        require(serialToOwner[serialNumber] == from, 'Not correct owner of serialnumber');
        serialToOwner[serialNumber] = to;
        ownerSerialCount[to]++;
        ownerSerialCount[from]--;
    }

    function getSerial(uint256 tokenId, uint256 index) public view returns (uint256) {
        if(tokenIdToSerials[tokenId].length == 0) {
            return 0;
        } else {
            return tokenIdToSerials[tokenId][index];
        }
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
           uint256 serialNumber = tokenIdToSerials[tokenId][i];
           if (serialToOwner[serialNumber] == owner) {
               return serialNumber;
           }
        }
        return 0;
    }

    function getOwnerOfSerial(uint256 serialNumber) public view returns (address) {
        return serialToOwner[serialNumber];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) public view returns (uint256) {
        return serialToTokenId[serialNumber];
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}
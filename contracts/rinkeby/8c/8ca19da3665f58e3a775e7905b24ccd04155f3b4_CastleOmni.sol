/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

interface ICommoner {
    // struct to store each token's traits
    struct Commoner {
        uint8 head;
        uint8 breed;
        uint8 palette;
        uint8 bodyType;
        uint8 clothes;
        uint8 accessory;
        uint8 background;
        uint8 smithing;
        uint8 alchemy;
        uint8 cooking;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Commoner memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwner(uint256 id, address who_) external view returns (bool);
    function pull(address owner, uint256[] calldata ids) external;
    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external;
    function transfer(address to, uint256 tokenId) external;
}

// import "../../extLib/omnichain/interfaces/ILayerZeroUserApplicationConfig.sol";
interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// import "../../extLib/omnichain/interfaces/ILayerZeroEndpoint.sol";
interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// import "../../extLib/omnichain/interfaces/ILayerZeroReceiver.sol";
interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

abstract contract NonblockingReceiver is ILayerZeroReceiver {

    address implementation_;
    address public admin;
    ILayerZeroEndpoint internal endpoint;

    struct FailedMessages {
        uint payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);
    event MessageSolved(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        require(msg.sender == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), 
            "NonblockingReceiver: invalid source sending contract");

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public {
        // only internal transaction
        require(msg.sender == address(this), "NonblockingReceiver: caller must be Bridge.");

        // handle incoming message
        _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function
    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) virtual internal;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _txParam) internal {
        endpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _txParam);
    }

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(failedMsg.payloadHash != bytes32(0), "NonblockingReceiver: no stored message");
        require(_payload.length == failedMsg.payloadLength && keccak256(_payload) == failedMsg.payloadHash, "LayerZero: invalid payload");
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote) external {
    //     require(msg.sender == admin, "not admin");
    //     trustedRemoteLookup[_chainId] = _trustedRemote;
    // }
}

/// @dev A simple contract to orchestrate comings and going from the Commoners
contract CastleOmni is NonblockingReceiver {

    // address implementation_;
    // address public admin;
    
    uint gasForDestinationLzReceive;

    address public commoners;
    address public treat;

    mapping (address => address) public reflection;
    mapping (uint256 => address) public commonerOwner;

    function initialize(address _layerZeroEndpoint, address commoner_, address treat_) external {
        require(msg.sender == admin);
        // portal = portal_;
        commoners   = commoner_;
        treat = treat_;

        gasForDestinationLzReceive = 350000;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote) external {
        require(msg.sender == admin, "not admin");
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint newVal) external {
        require(msg.sender == admin, "not admin");
        gasForDestinationLzReceive = newVal;
    }

    function setReflection(address key_, address reflection_) external {
        require(msg.sender == admin);
        reflection[key_] = reflection_;
        reflection[reflection_] = key_;
    }

    /// @dev Send Doges and tokens to Other chain
    function travel(uint16 _chainId, uint256[] calldata dogeIds, uint256 treatAmount) public payable {
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");
        address target = reflection[address(this)];

        uint256 dogesLen   = dogeIds.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((dogesLen > 0 ? dogesLen + 1 : 0) + (treatAmount > 0 ? 1 : 0));

        if (dogesLen > 0) {
            _pullIds(commoners, dogeIds);

            // This will create doges exactly as they exist in this chain
            for (uint256 i = 0; i < dogeIds.length; i++) {
                calls[i] = _buildData(dogeIds[i]);
            }

            calls[dogesLen] = abi.encodeWithSelector(this.unstakeMany.selector,reflection[commoners], msg.sender,  dogeIds);
            currIndex += dogesLen + 1;
        }

        if (treatAmount > 0) {
            ERC20Like(treat).burn(msg.sender, treatAmount);
            calls[currIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(treat)], msg.sender, treatAmount);
            currIndex++;
        }

        // PortalLike(portal).sendMessage(abi.encode(target, calls));
        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(target, calls);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
          
        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        require(msg.value >= messageFee, "GG: msg.value not enough to cover messageFee. Send gas for message fees");

        // endpoint.send{value: msg.value}(
        //     _chainId,                           // destination chainId
        //     trustedRemoteLookup[_chainId],      // destination address of nft contract
        //     payload,                            // abi.encoded()'ed bytes
        //     payable(msg.sender),                // refund address
        //     address(0x0),                       // 'zroPaymentAddress' unused for this
        //     adapterParams                       // txParameters 
        // );
        _lzSend(
            _chainId,                           // destination chainId
            // trustedRemoteLookup[_chainId],      // destination address of nft contract
            payload,                            // abi.encoded()'ed bytes
            payable(msg.sender),                // refund address
            address(0x0),                       // 'zroPaymentAddress' unused for this
            adapterParams                       // txParameters 
        );
    }

    /// @dev Fee estimation to send Doges and tokens to Other chain
    function estimateFee(uint16 _chainId, uint256[] calldata dogeIds, uint256 treatAmount) public view returns (uint) {
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");
        address target = reflection[address(this)];

        uint256 dogesLen   = dogeIds.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((dogesLen > 0 ? dogesLen + 1 : 0) + (treatAmount > 0 ? 1 : 0));

        if (dogesLen > 0) {
            // _pullIds(commoners, dogeIds);

            // This will create doges exactly as they exist in this chain
            for (uint256 i = 0; i < dogeIds.length; i++) {
                calls[i] = _buildData(dogeIds[i]);
            }

            calls[dogesLen] = abi.encodeWithSelector(this.unstakeMany.selector,reflection[commoners], msg.sender,  dogeIds);
            currIndex += dogesLen + 1;
        }

        if (treatAmount > 0) {
            // ERC20Like(treat).burn(msg.sender, treatAmount);
            calls[currIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(treat)], msg.sender, treatAmount);
            currIndex++;
        }

        // PortalLike(portal).sendMessage(abi.encode(target, calls));
        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(target, calls);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
          
        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        return messageFee;
    }

    function callCommoner(bytes calldata data) external {
        _onlyPortal();

        (bool succ, ) = commoners.call(data);
        require(succ);
    }

    event D(uint tt);
    event DAD(address al);

    function unstakeMany(address token, address owner, uint256[] calldata ids) external {
        _onlyPortal();

        emit DAD(token);

        for (uint256 i = 0; i < ids.length; i++) {  
            emit D(ids[i]);
            if (token == commoners)   delete commonerOwner[ids[i]];
            ERC721Like(token).transfer(owner, ids[i]);
        }
    }

    function mintToken(address token, address to, uint256 amount) external { 
        _onlyPortal();

        ERC20Like(token).mint(to, amount);
    }

    function _pullIds(address token, uint256[] calldata ids) internal {
        // The ownership will be checked to the token contract
        ICommoner(token).pull(msg.sender, ids);
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == commoners);
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(msg.sender, ids[i], owner);
        }
    }

    function _buildData(uint256 id) internal view returns (bytes memory data) {
        ICommoner.Commoner memory s_ = ICommoner(commoners).getTokenTraits(id);
        data = abi.encodeWithSelector(this.callCommoner.selector, abi.encodeWithSelector(ICommoner.adjust.selector, id, s_.head, s_.breed, s_.palette, s_.bodyType, s_.clothes, s_.accessory, s_.background, s_.smithing, s_.alchemy, s_.cooking));
    }

    function _stake(address token, uint256 id, address owner) internal {
        require(commonerOwner[id] == address(0), "already staked");
        require(msg.sender == token, "not dogewood contract");
        require(ERC721Like(token).ownerOf(id) == address(this), "doge not transferred");

        if (token == commoners)   commonerOwner[id]  = owner;
    }

    function _onlyPortal() view internal {
        require(msg.sender == address(this), "NonblockingReceiver: caller must be Bridge.");
    } 

    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        (address target, bytes[] memory calls ) = abi.decode(_payload, (address, bytes[]));
        for (uint256 i = 0; i < calls.length; i++) {
            (bool succ, ) = target.call(calls[i]);
            // emit CallMade(target, succ, calls[i]);
            // require(succ, "call failed");
        }
        emit MessageSolved(_srcChainId, _srcAddress, _nonce, _payload);
    }
}
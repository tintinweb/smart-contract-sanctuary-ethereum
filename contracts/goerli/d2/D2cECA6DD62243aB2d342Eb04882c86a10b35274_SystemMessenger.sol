/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: SystemMessenger.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/SystemMessenger.sol
* Docs: https://docs.synthetix.io/contracts/SystemMessenger
*
* Contract Dependencies: 
*	- IAddressResolver
*	- ISystemMessenger
*	- MixinResolver
*	- Owned
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2022 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.synthetix.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.synthetix.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    // Restricted: used internally to Synthetix
    function issueSynths(address from, uint amount) external;

    function issueSynthsOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxSynths(address from) external;

    function issueMaxSynthsOnBehalf(address issueFor, address from) external;

    function burnSynths(address from, uint amount) external;

    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnSynthsToTarget(address from) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external;

    function teleportSynth(uint targetChainId, bytes32 currencyKey, address from, uint amount) external returns (bool);

    function receiveTeleportedSynth(bytes32 currencyKey, address from, uint amount) external returns (bool);

    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external returns (uint totalRedeemed, uint amountToLiquidate);

    function setCurrentPeriodId(uint128 periodId) external;
}


// Inheritance


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.synthetix.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
interface ISystemMessenger {
    // send a message only to one chain
    function post(
        uint targetChainId,
        bytes32 targetContract,
        bytes calldata data,
        uint32 gasLimit
    ) external;

    // send a copy of this message to all registered chains
    function broadcast(
        bytes32 targetContract,
        bytes calldata data,
        uint32 gasLimit
    ) external;
    
    // called by relayer to finalize message sent cross-chain
    function recv(
        uint srcChainId,
        uint srcNonce,
        bytes32 targetContract,
        bytes calldata data,
        uint32 gasLimit,
        bytes calldata sigs
    ) external;

    function addChain(uint chainId, address messenger) external;
    function removeChain(uint chainId) external;

    function authorizeSigner(address signer) external;
    function revokeSigner(address signer) external;

    function setRequiredSignatures(uint count) external;
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/systemstatus
contract SystemMessenger is Owned, MixinResolver, ISystemMessenger {

    bytes32 public constant CONTRACT_NAME = "SystemMessenger";

    uint[] public activeChains;

    mapping(uint => address) public messengerAddresses;
    mapping(uint => uint) public outgoingNonces;
    mapping(uint => uint) public incomingNonces;

    mapping(address => bool) public signers;
    uint public requiredSignatures;

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {
        requiredSignatures = 1;
    }

    /* ========== VIEWS ========== */
    function getMessageHash(
        uint srcChainId,
        uint srcNonce,
        bytes32 targetContract,
        bytes memory data,
        uint32 gasLimit
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                bytes32("Synthetixv2x"),
                srcChainId,
                srcNonce,
                targetContract, 
                data, 
                gasLimit
            )
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // send a message only to one chain
    function post(
        uint targetChainId,
        bytes32 targetContract,
        bytes memory data,
        uint32 gasLimit
    ) public onlyAuthorizedMessenger {
        emit MessagePosted(targetChainId, outgoingNonces[targetChainId]++, targetContract, data, gasLimit);
    }

    // sends a copy of this message to all chains synthetix is deployed to
    function broadcast(
        bytes32 targetContract,
        bytes memory data,
        uint32 gasLimit
    ) public onlyAuthorizedMessenger {
        for (uint i = 0;i < activeChains.length;i++) {
            post(activeChains[i], targetContract, data, gasLimit);
        }
    }

    function recv(
        uint srcChainId,
        uint srcNonce,
        bytes32 targetContract,
        bytes calldata data,
        uint32 gasLimit,
        bytes calldata sigs
    ) external {
        require(incomingNonces[srcChainId]++ == srcNonce, "can only submit next message nonce");

        bytes32 signHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                getMessageHash(srcChainId, srcNonce, targetContract, data, gasLimit)
            )
        );

        require(validateSignatures(signHash, sigs) >= requiredSignatures, "invalid signature blob");

        // not using `requireAndGetAddress` becuase the message ID would be blocked otherwise
        // when `target.call` is executed below, it will simply fail the internal call without blocking the incoming nonce increment
        address target = resolver.getAddress(targetContract);

        (bool success, bytes memory returned) = target.call(data);

        emit MessageProcessed(srcChainId, srcNonce, targetContract, data, gasLimit, success, returned);
    }

    function addChain(uint chainId, address messenger) external onlyOwnerOrSelf {
        messengerAddresses[chainId] = messenger;
        activeChains.push(chainId);
    }

    function removeChain(uint chainId) external onlyOwnerOrSelf {
        messengerAddresses[chainId] = address(0);
        incomingNonces[chainId] = 0;
        outgoingNonces[chainId] = 0;
        
        for (uint i = 0;i < activeChains.length;i++) {
            if (activeChains[i] == chainId) {
                activeChains[i] = activeChains[activeChains.length - 1];

                activeChains.pop();
                return;
            }
        }

        revert("could not find specified chain id");
    }

    function authorizeSigner(address signer) external onlyOwnerOrSelf {
        signers[signer] = true;
    }

    function revokeSigner(address signer) external onlyOwnerOrSelf {
        signers[signer] = false;
    }

    function setRequiredSignatures(uint count) external onlyOwnerOrSelf {
        requiredSignatures = count;
    }

    /* ========== INTERNAL FUNCTIONS ========= */

    function validateSignatures(bytes32 signHash, bytes memory signatures) internal view returns (uint) {
        if (signatures.length == 0) {
            return 0;
        }

        address lastSigner = address(0);

        uint signatureCount = signatures.length / 65;

        for (uint256 i = 0; i < signatureCount; i++) {
            address signer = recoverSigner(signHash, signatures, i);

            if (signer <= lastSigner) {
                return 0; // Signers must be different
            }

            lastSigner = signer;

            if (!signers[signer]) {
                return 0;
            }
        }

        return signatureCount;
    }

    /**
    * copied exactly from https://github.com/argentlabs/argent-contracts/blob/develop/contracts/modules/common/Utils.sol
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /* ========== MODIFIERS ======== */
    modifier onlyAuthorizedMessenger {
        require(msg.sender == resolver.getAddress("Issuer") || msg.sender == owner, "Only authorized senders can call");
        _;
    }

    modifier onlyOwnerOrSelf {
        require(msg.sender == address(this) || msg.sender == owner, "Only owner or self can call");
        _;
    }

    /* ========== EVENTS ========== */
    event MessagePosted(uint indexed targetChainId, uint indexed nonce, bytes32 indexed targetContract, bytes data, uint32 gasLimit);
    event MessageProcessed(uint indexed srcChainId, uint indexed nonce, bytes32 indexed targetContract, bytes data, uint32 gasLimit, bool success, bytes resultData);
}
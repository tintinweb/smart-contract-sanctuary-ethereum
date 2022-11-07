//SPDX-License-Identifier: MIT
//only mint
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

//import chainlink ownable

import "hardhat/console.sol";
import "./NEURAL/NEURAL.sol";
import "./AiAlbumMint.sol";

contract AiAlbum is ChainlinkClient, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    uint8 public maxMint = 5;
    uint8 public mintCount = 2;
    uint16 private dropCount = 0;
    uint256 private BASE_COST = 0.000045 ether;
    uint256 private DIFFICULTY_RAMP = 3;
    uint256 private BASE_DIFFICULTY =
        uint256(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        ) / uint256(300);

    address private The_Dude = 0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b;

    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    bytes32[] TOKENS;

    //dropType 0 = off, 1 = signature, 2 = FCFS, 3 = POW 4 = Auction

    struct DropInformation {
        uint256 id;
        uint256 price;
        address tokenContract;
        address contractAddress;
        uint256[2] time;
        uint8[] dropTypes;
        uint32 count;
        uint32 amount;
        DropAttributes attributes;
    }

    struct DropAttributes {
        uint32 maxMint;
        uint32 mintCount;
    }
    struct DropUsers {
        mapping(address => uint32) minted;
    }
    struct SignatureData {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct ClaimedTokens {
        mapping(uint256 => bool) claimed;
    }
    struct DropDescriptionInformation {
        bytes32 name;
        bytes32 description;
        bytes32 baseUrl;
        bytes32 errorMessage;
    }
    struct ContractInformation {
        uint256 supply;
        uint256 dropCount;
        uint256 currentSupply;
        mapping(uint256 => uint256) dropIds;
        mapping(address => bool) delegate;
    }

    mapping(address => ContractInformation) private contractInformation;
    mapping(uint256 => uint256) internal ID_TO_INDEX;
    mapping(uint256 => DropUsers) private dropUsers;
    mapping(uint256 => ClaimedTokens) private claimedTokensByDrop;
    mapping(uint256 => DropInformation) public drops;
    mapping(uint256 => DropDescriptionInformation) private dropDescriptions;
    mapping(address => uint256) public nonces;
    mapping(address => NEURAL) private contracts;
    mapping(address => AiAlbumMint) private contracts720;

    event Mined(uint256 indexed _tokenId, bytes32 hash);
    event Withdraw(uint256 indexed _tokenId, uint256 value);

    constructor() {
        dropDescriptions[0] = DropDescriptionInformation(
            bytes32(""),
            bytes32(""),
            bytes32(""),
            bytes32("Drop not started.")
        );
        dropDescriptions[1] = DropDescriptionInformation(
            bytes32("AccessList Drop"),
            bytes32("AccessList members only."),
            bytes32(""),
            bytes32("Drop is on Signature mode.")
        );
        dropDescriptions[2] = DropDescriptionInformation(
            bytes32("First Come First Serve Drop"),
            bytes32("This drop is for everyone."),
            bytes32(""),
            bytes32("Drop is on FCFS mode.")
        );
        dropDescriptions[3] = DropDescriptionInformation(
            bytes32("Proof of Work Drop"),
            bytes32("Find correct hash to mint."),
            bytes32(""),
            bytes32("Drop is on POW mode.")
        );
        dropDescriptions[4] = DropDescriptionInformation(
            bytes32("Auction Drop"),
            bytes32("Highest big wins."),
            bytes32(""),
            bytes32("Drop is on Auction mode.")
        );
        dropDescriptions[5] = DropDescriptionInformation(
            bytes32("Neural Token Drop"),
            bytes32("mint with NEURAL Token."),
            bytes32(""),
            bytes32("Drop is on NEURAL Token mode.")
        );
        dropDescriptions[6] = DropDescriptionInformation(
            bytes32("Token Drop"),
            bytes32("Mint with approved token."),
            bytes32(""),
            bytes32("Drop is on Token mode.")
        );
        dropDescriptions[7] = DropDescriptionInformation(
            bytes32("Airdrop Drop"),
            bytes32("Airdrop tokens to users."),
            bytes32(""),
            bytes32("Drop is an airdrop.")
        );
        dropDescriptions[8] = DropDescriptionInformation(
            bytes32("Claim Drop"),
            bytes32("Claim for airdrop."),
            bytes32(""),
            bytes32("Drop is a claim.")
        );
        dropDescriptions[9] = DropDescriptionInformation(
            bytes32("Premint Drop"),
            bytes32("Premint tokens to one address."),
            bytes32(""),
            bytes32("Drop is a premint.")
        );
        dropDescriptions[10] = DropDescriptionInformation(
            bytes32(""),
            bytes32(""),
            bytes32(""),
            bytes32("Drop ended.")
        );
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    modifier adminAccess() {
        require(isGod(msg.sender), "Admin access only.");
        _;
    }

    modifier contractOwner(uint256 _drop) {
        require(
            contractInformation[drops[_drop].contractAddress].delegate[
                msg.sender
            ],
            "Contract delegate only."
        );
        _;
    }

    modifier determineDrop(uint256 _drop, uint256 _stage) {
        DropInformation storage drop = drops[_drop];
        uint8 stageIndex = 0;

        unchecked {
            require(_drop < dropCount, "Drop does not exist.");
            //TODO: Clean this up. I think I can make function just check timestamps and not all this other math. (Start at end as well as if that one is true the rest will be true)

            uint256 dropTime = drop.time[0];
            uint256 dropDuration = drop.time[1] * 1000;
            uint256 dropTimestamp = dropTime - (dropTime % 1800) + dropDuration;
            for (uint256 index = 0; index < drop.dropTypes.length; index++) {
                if (
                    int256(block.timestamp) -
                        (int256(dropTimestamp) +
                            (int256(dropDuration) * (abs(int256(index)) + 1))) >
                    0
                ) {
                    if (drop.dropTypes.length > stageIndex + 1) {
                        stageIndex++;
                    }
                }
            }
        }
        require(drop.dropTypes[stageIndex] == _stage, "Wrong stage.");

        _;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function isGod(address addy) private view returns (bool) {
        bool amIGod = addy == owner() || addy == The_Dude;
        return amIGod;
    }

    function onlyValidAccess(
        uint256 _nonce,
        bytes32 hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private {
        require(_nonce == nonces[msg.sender], "Invalid nonce.");
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        require(isGod(sender), "Invalid access message.");
        nonces[msg.sender]++;
    }

    function generationOf(uint256 _tokenId)
        private
        pure
        returns (uint256 generation)
    {
        for (generation = 0; _tokenId > 0; generation++) {
            _tokenId /= 2;
        }
        return generation - 1;
    }

    function setTokenContract(address _token) public adminAccess {
        contracts[_token] = NEURAL(_token);
    }

    function set720TokenContract(address _token) public adminAccess {
        contracts720[_token] = AiAlbumMint(_token);
    }

    function grabDropPrice(uint256 _drop) public view returns (uint256) {
        return drops[_drop].price;
    }

    function getMintNumber(uint256 _drop, address wallet)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _minted = dropUsers[_drop].minted[wallet];
        uint256 _maxMint = drops[_drop].attributes.maxMint;
        uint256 _mintCount = drops[_drop].attributes.mintCount;
        return (_minted, _maxMint, _mintCount);
    }

    function checkDropInventory(
        uint32 _amount,
        uint256 _drop,
        uint256 _stage,
        address wallet
    ) external {
        // if (dropUsers[_drop].minted[msg.sender] == 0) {
        //     dropUsers[_drop].minted[msg.sender] = drops[_drop].attributes.mintCount + 1;
        // }
        DropInformation storage drop = drops[_drop];

        unchecked {
            dropUsers[_drop].minted[wallet] += _amount;
            drop.count += _amount;
        }
        if (_stage != 7 && _stage != 8)
            require(_amount <= drop.attributes.maxMint, "Max mint per TX.");
        require(
            dropUsers[_drop].minted[wallet] <= drop.attributes.mintCount,
            "Over limit."
        );
        require(drop.count <= drop.amount, "Inventory is Full.");
    }

    function checkDropInventorySignature(uint32 _amount, uint256 _drop)
        private
    {
        unchecked {
            drops[_drop].count += _amount;
            contractInformation[drops[_drop].contractAddress]
                .currentSupply += _amount;
        }
        require(
            contractInformation[drops[_drop].contractAddress].currentSupply <
                contractInformation[drops[_drop].contractAddress].supply,
            "Drop inventory is Full."
        );
    }

    // function dropCurrentSupply(uint256 _drop)
    //     public
    //     view
    //     dropExists(_drop)
    //     returns (uint256)
    // {
    //     return drops[_drop].count;
    // }

    function updateContractLimit(address _contract, uint256 _limit)
        public
        adminAccess
    {
        contractInformation[_contract].supply = _limit;
    }

    /**
     * @dev Create NFT drop. (Contract owner or Delegate to contract)
     * The call will create a new drop and return the drop ID.
     *
     * @param _price how much ether is required to mint a token.
     * @param _token this is the address of the token that needs to be checked for airdrops, 3rd party mints,etc. Enter 0x0 if not applicable.
     * @param _time This is the time created and the interval in minutes that the drop will continue to d5rop for.
     * @param _dropTypes[] Each drop type will be changed based on interval in time array. If the drop is not active, it should be set to 0.
     * @param _amount The amount of tokens to be in the drop. Supply can't be more than maxSupply of total contract, or over 1000000000.
     */

    function createDrop(
        uint256 _price,
        uint8[] calldata _dropTypes,
        uint32 _amount,
        uint256 _time,
        address _contract,
        address _token,
        DropAttributes calldata _attributes
    ) external returns (uint256) {
        if (contractInformation[_contract].supply != 0) {
            require(
                contractInformation[_contract].currentSupply + _amount <=
                    contractInformation[_contract].supply,
                string(
                    abi.encodePacked(
                        "Amount is too high.",
                        Strings.toString(contractInformation[_contract].supply)
                    )
                )
            );
        } else {
            contractInformation[_contract].supply = _amount;
        }
        if (contractInformation[_contract].delegate[msg.sender]) {
            require(
                contractInformation[_contract].delegate[msg.sender],
                "Not delegate."
            );
        } else {
            require(
                AiAlbumMint(_contract).owner() == msg.sender,
                "Not contract owner."
            );
            contracts720[_contract] = AiAlbumMint(_contract);
            contractInformation[_contract].delegate[msg.sender] = true;
        }

        drops[dropCount] = DropInformation(
            dropCount,
            _price,
            _token,
            _contract,
            [block.timestamp, uint256(_time) * 60],
            _dropTypes,
            0,
            _amount,
            _attributes
        );
        //for loop throigh dropCount and determine drop count and make sure amount is not over all same contract drops
        uint256 addedSupply = _amount + contracts720[_contract].totalSupply();

        require(
            addedSupply <= contractInformation[_contract].supply,
            string(
                abi.encodePacked(
                    "Amount is too high ",
                    Strings.toString(contractInformation[_contract].supply),
                    Strings.toString(addedSupply)
                )
            )
        );
        contractInformation[_contract].dropIds[
            contractInformation[_contract].dropCount
        ] = dropCount;
        contractInformation[_contract].dropCount++;
        if (_dropTypes[0] == 9) {
            AdminMintPrivate(_amount, dropCount, _token);
        }
        dropCount++;

        // currentSupply = currentSupply + _amount;

        return dropCount - 1;
    }

    /**
     * @dev update NFT drop. (Contract owner or Delegate to contract)- !! Make sure to double check all values, as this will overwrite the drop's values !!
     * The call will create a new drop and return the drop ID.
     *
     * @param _id The drop ID.
     *                    If you change amounts, it needs this information to calculate the correct amount of tokens that have already been minted.
     * @param _price how much ether is required to mint a token.
     * @param _token this is the address of the token that needs to be checked for airdrops, 3rd party mints,etc. Enter 0x0 if not applicable.
     * @param _time This is the time created and the interval in minutes that the drop will continue to drop for.
     * @param _dropTypes[] Each drop type will be changed based on interval in time array. If the drop is not active, it should be set to 0.
     * @param _amount The amount of tokens to be in the drop. Supply can't be more than maxSupply of total contract, or over 1000000000.
     */

    function updateDrop(
        uint256 _id,
        uint256 _price,
        uint8[] calldata _dropTypes,
        uint32 _amount,
        uint256 _time,
        address _contract,
        address _token,
        DropAttributes calldata _attributes
    ) external contractOwner(_id) {
        if (contractInformation[_contract].supply != 0)
            require(
                _amount + contractInformation[_contract].currentSupply <=
                    contractInformation[_contract].supply,
                string(
                    abi.encodePacked(
                        "Amount is too high.",
                        Strings.toString(contractInformation[_contract].supply)
                    )
                )
            );

        //  currentSupply -= _lastAmount;

        uint256 addedSupply = _amount;
        for (
            uint256 i = 0 + 1;
            i < contractInformation[_contract].dropCount;
            i++
        ) {
            addedSupply += drops[contractInformation[_contract].dropIds[i]]
                .amount;
        }
        require(
            addedSupply <= contractInformation[_contract].supply,
            string(
                abi.encodePacked(
                    "Amount is too high ",
                    Strings.toString(contractInformation[_contract].supply),
                    Strings.toString(addedSupply)
                )
            )
        );

        drops[_id] = DropInformation(
            _id,
            _price,
            _token,
            _contract,
            [block.timestamp, uint256(_time) * 60],
            _dropTypes,
            drops[_id].count,
            _amount,
            _attributes
        );

        //  currentSupply += _amount;

        // currentSupply = currentSupply * dropCount + _amount;
    }

    function singatureClaimHash(
        uint256 _amount,
        uint256 _drop,
        uint256 _nonce,
        uint256 _ids
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _nonce,
                    _drop,
                    _amount,
                    _ids
                )
            );
    }

    function addIdArray(uint256[] calldata _ids)
        private
        pure
        returns (uint256)
    {
        uint256 ids = 0;
        for (uint256 i = 0; i < _ids.length; i++) {
            ids += _ids[i];
        }
        return ids;
    }

    function loopThroughClaimIds(
        uint256[3] calldata _data,
        uint256[] calldata _ids
    ) private returns (bytes32) {
        uint256 ids = 0;

        for (uint256 index = 0; index < _ids.length; index++) {
            bool isClaimed = false;
            ids += _ids[index];
            if (claimedTokensByDrop[_data[2]].claimed[_ids[index]]) {
                isClaimed = true;
            }
            require(!isClaimed, "TokenID has already claimed this drop.");
            claimedTokensByDrop[_data[2]].claimed[_ids[index]] = true;
        }
        //[8, nonce, 5]    nonce, drop.toString(), amount, ids
        return singatureClaimHash(uint256(_data[0]), _data[2], _data[1], ids);
    }

    // function testMine(uint256 _amount, uint256 nonce) public view {
    //  ///   uint256 tokenId =  totalSupply() + _amount;
    //     uint256 generation = generationOf(tokenId);

    //     uint256 difficulty = BASE_DIFFICULTY / (DIFFICULTY_RAMP**generation);
    //     if (generation > 13) {
    //         //Token 16384
    //         difficulty /= (tokenId - 2**14 + 1);
    //     }

    //     //   uint256 cost = (2**generation - 1) * BASE_COST;

    //     bytes32 hash;

    //     hash = keccak256(
    //         abi.encodePacked(
    //             msg.sender,
    //             TOKENS[ID_TO_INDEX[tokenId - 1]],
    //             nonce
    //         )
    //     );

    //     require(uint256(hash) < difficulty, "difficulty");

    //     hash = keccak256(abi.encodePacked(hash, block.timestamp));
    // }

    function AdminMintPrivate(
        uint32 _amount,
        uint256 _drop,
        address _to
    ) private {
        this.checkDropInventory(1, _drop, 0, msg.sender);
        contracts720[drops[_drop].contractAddress].mint(_to, _amount);
        // _mint(_to, _amount);
    }

    function AdminMint(
        uint32 _amount,
        uint256 _drop,
        address _to
    ) external adminAccess {
        AdminMintPrivate(_amount, _drop, _to);
    }

    // function NEURALMint(
    //     uint32 _amount,
    //     uint256 _drop,
    //     uint256 _price
    // ) external determineDrop(_drop, 5) callerIsSender {
    //     uint256 total = drops[_drop].price * _amount;
    //     require(_price >= total, "Please pay more for this mint.");
    //     contracts[drops[_drop].tokenContract].burn(
    //         msg.sender,
    //         _price * _amount
    //     );
    //     this.checkDropInventory(_amount, _drop);
    //     contracts720[drops[_drop].contractAddress].mint(msg.sender, _amount);
    //     // _mint(msg.sender, _amount);
    // }

    function TokenMint(
        uint32 _amount,
        uint256 _drop,
        uint256 _price
    ) external determineDrop(_drop, 6) callerIsSender {
        require(_price >= drops[_drop].price, "Price is too low.");
        contracts[drops[_drop].tokenContract].transferFrom(
            msg.sender,
            address(this),
            _price
        );
        this.checkDropInventory(_amount, _drop, 6, msg.sender);
        contracts720[drops[_drop].contractAddress].mint(msg.sender, _amount);
        //  _mint(msg.sender, _amount);
    }

    function AirDrop(uint256 _drop) public determineDrop(_drop, 7) adminAccess {
        //drops[_drop]
        this.checkDropInventory(5, _drop, 7, msg.sender);
        for (uint256 index = 0; index < 5; index++) {
            contracts720[drops[_drop].contractAddress].mint(
                contracts720[drops[_drop].contractAddress].ownerOf(index),
                1
            );
        }
    }

    function FCFSMint(uint8 _amount, uint256 _drop)
        external
        payable
        callerIsSender
        determineDrop(_drop, 2)
    {
        //TODO: Need to clean this up for gas savings
        this.checkDropInventory(_amount, _drop, 2, msg.sender);
        require(msg.value >= drops[_drop].price * _amount, "Price wrong.");

        contracts720[drops[_drop].contractAddress].mint(msg.sender, _amount);

        // _mint(msg.sender, _amount);
    }

    function POWMint(uint256 _amount, uint256 _drop)
        public
        payable
        callerIsSender
    {
        require(_drop <= dropCount - 1, "Drop does not exist.");
    }

    //_data 0 = amount, 1 = nonce, 2 = drop
    function Claim(
        uint256[3] calldata _data,
        SignatureData calldata sig,
        uint256[] calldata _ids
    ) external payable callerIsSender determineDrop(_data[2], 8) {
        require(
            _ids.length > 0 && _data[0] <= 10,
            "You can only claim 10 at a time."
        );
        bytes32 hash = loopThroughClaimIds(_data, _ids);

        require(msg.value >= drops[_data[2]].price * _data[0], "Price wrong.");
        onlyValidAccess(_data[1], hash, sig.v, sig.r, sig.s);
        this.checkDropInventory(uint32(_data[0]), _data[2], 8, msg.sender);
        contracts720[drops[_data[2]].contractAddress].mint(
            msg.sender,
            uint32(_data[0])
        );
        //_mint(msg.sender, _data[0]);
    }

    function SignatureMint(
        uint32 _amount,
        uint256 _nonce,
        uint256 _drop,
        SignatureData calldata sig
    ) external payable callerIsSender determineDrop(_drop, 1) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _nonce,
                _drop,
                uint256(_amount)
            )
        );

        onlyValidAccess(_nonce, hash, sig.v, sig.r, sig.s);
        // require(
        //     drops[_drop].count < drops[_drop].amount,
        //     "Drop inventory is Full."
        // );
        checkDropInventorySignature(_amount, _drop);
        require(msg.value >= drops[_drop].price * _amount, "Price wrong.");
        contracts720[drops[_drop].contractAddress].mint(msg.sender, _amount);
        //  _mint(msg.sender, _amount);
    }

    // functions for users to get information
    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        return "placeholder.com/metadata.json";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../AiAlbum.sol";

contract NEURAL is ERC20, Ownable, ReentrancyGuard {
    AiAlbum ai;

    address testControllerAddy;

    uint256 public rewardStartDate = block.timestamp;

    uint256 contractRewardBalance = 0;
    uint256 contractLastRewardBlock = block.number;

    struct TokenInfo {
        uint256 claimDate;
        uint8[4] attributes;
    }

    struct ClaimReward {
        address claimer;
        uint256 reward;
        uint256 lastBlock;
    }

    struct DropInformation {
        uint256 id;
        uint256 price;
        uint256[2] time;
        uint8[] dropTypes;
        uint32 amount;
    }

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;
    mapping(uint256 => TokenInfo) tokenInfo;
    mapping(address => ClaimReward) public rewards;

    constructor(address _aiAddress) ERC20("NEURAL", "NEURAL") {
        contractRewardBalance = 0;
        controllers[msg.sender] = true;
        controllers[address(this)] = true;
        controllers[_aiAddress] = true;
        rewards[address(this)] = ClaimReward(address(this), 0, block.number);
        ai = AiAlbum(_aiAddress);
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    /**
     * mints $QTER to a recipient
     * @param to the recipient of the $QTER
     * @param amount the amount of $QTER to mint
     */

    function mint(address to, uint256 amount) public {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function testController() public {
        testControllerAddy = msg.sender;
    }

    /**
     * burns $QTER from a holder
     * @param from the holder of the $QTER
     * @param amount the amount of $QTER to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setAIGame(address _address) public onlyOwner {
        ai = AiAlbum(_address);
    }

    // function getStakedTimed(uint256 tokenId) public view returns (uint256) {
    //     return ai.getStakedTime(tokenId);
    // }

    function aiContractClaim(uint256 startBlock, uint256 rewardPrice) public {
        require(controllers[msg.sender], "Only controllers can mint");
        require(startBlock > contractLastRewardBlock, "No rewards to claim");
        mint(address(ai), rewardPrice);
        contractLastRewardBlock = block.number;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function getTotalTime(uint256 _tokenId) public view returns (uint256) {
        if (tokenInfo[_tokenId].claimDate == 0) {
            return block.timestamp - rewardStartDate;
        }
        return block.timestamp - tokenInfo[_tokenId].claimDate;
    }

    // function getRewardAmount(uint256 tokenId) public view returns (uint256) {
    //     uint256[5] memory attributes = ai.tokenAttributes(tokenId);
    //     uint256 tokenYield = attributes[0]; //multiplier for x1 token per day
    //     uint256 tokenTime = getTotalTime(tokenId) * 1 ether; //current date minus reward claim date
    //     tokenTime = tokenTime / 86400;
    //     tokenTime = tokenTime * tokenYield;
    //     //convert to ether
    //     uint256 amount = tokenTime;
    //     return amount;
    // }

    // function getRewardAmountNoEth(uint256 tokenId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     uint256[5] memory attributes = ai.tokenAttributes(tokenId);
    //     uint256 tokenYield = attributes[0]; //multiplier for x1 token per day
    //     uint256 tokenTime = getTotalTime(tokenId); //current date minus reward claim date
    //     tokenTime = tokenTime * tokenYield;
    //     //convert to ether
    //     uint256 amount = tokenTime;
    //     return amount;
    // }

    // function claimReward(uint256 tokenId) public {
    //     tokenOwnerOf(tokenId);
    //     uint256 rewardAmount = getRewardAmount(tokenId);
    //     tokenInfo[tokenId].claimDate = block.timestamp;
    //     _mint(msg.sender, rewardAmount);
    // }

    // function claimRewardNoEth(uint256 tokenId) public {
    //     tokenOwnerOf(tokenId);
    //     uint256 rewardAmount = getRewardAmountNoEth(tokenId);
    //     tokenInfo[tokenId].claimDate = block.timestamp;
    //     _mint(msg.sender, rewardAmount);
    // }

    function AiGameMint(
        address sender,
        uint32 _amount,
        uint256 _price,
        uint256 _drop
    ) public {
        require(msg.sender == address(ai), "Only AiGame can mint");
        uint256 dropPrice = ai.grabDropPrice(_drop);
        uint256 total = dropPrice * _amount;
        require(_price >= total, "Please pay more for this mint.");
        _burn(sender, _price * _amount);
        //    contractRewardBalance += (total * 10) / 100;
    }

    function tokenOwner(uint256 tokenId) public view returns (address) {
        //     return ai.ownerOf(tokenId);
    }

    function tokenOwnerOf(uint256 tokenId) private view {
        //  bool isOwner = ai.ownerOf(tokenId) == msg.sender;
        //  require(isOwner, "You do not own this token");
    }

    function checkBalance(address _sender) public view returns (uint256) {
        uint256 balance = balanceOf(_sender);
        return balance;
    }

    // function claimSnakeQTER(uint256 tokenId) public returns (uint256) {
    //     snakeTokenOwnerOf(tokenId);
    //     SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
    //     //get total time staked to increase the reward
    //     uint256 totalTimeStaked = (block.timestamp - info.stakeDate) / 86400;
    //     //get the reward amount based on last stake time;
    //     uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
    //         5;
    //     //reward add multiplayer for every month staked since last claim
    //     uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

    //     //reward add multiplier for every minute staked since last claim
    //     uint256 rewardTotal = (
    //         ((totalStakedSinceLastClaim * rewardTotalMultiplayer) / 60)
    //     ) * 1 ether;
    //     ai.setClaimTime(tokenId);
    //     _mint(msg.sender, rewardTotal);
    //     return rewardTotal;
    // }

    // function getTotalSnakeQTER(uint256 tokenId) public view returns (uint256) {
    //     SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
    //     //get total time staked to increase the reward
    //     uint256 totalTimeStaked = (block.timestamp - info.stakeDate) * 10;
    //     //get the reward amount based on last stake time;
    //     uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
    //         10;
    //     //reward add multiplayer for every day staked since last claim
    //     uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

    //     //reward add multiplier for every minute staked since last claim
    //     uint256 rewardTotal = (
    //         ((totalStakedSinceLastClaim + rewardTotalMultiplayer) / 60)
    //     ) * 1 ether;

    //     return rewardTotal;
    // }

    // function stakeSnakeTokensCount(uint256[] memory tokenIds, uint256 count)
    //     public
    // {
    //     //        uint256 stakeDate = ai.getStakeArray(tokenId)[0];

    //     ai.stakeTokens(count, msg.sender, tokenIds);
    //     // ai.tokenInfoList(tokenId).stakeDate = block.timestamp;
    // }

    // function stakeSnakeTokens(uint256[] memory tokenIds) public {
    //     //        uint256 stakeDate = ai.getStakeArray(tokenId)[0];

    //     for (uint256 index = 0; index < tokenIds.length; index++) {
    //         snakeTokenOwnerOf(tokenIds[index]);
    //         //ai.stakeToken(tokenIds[index]);
    //     }
    //     ai.stakeToken(tokenIds[0]);
    //     // ai.tokenInfoList(tokenId).stakeDate = block.timestamp;
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721G.sol";

//species, eyes, nose, mouth, background, accessories, accesoriesCount, first Name, last Name, sex,

contract AiAlbumMint is ERC721G, Ownable, ReentrancyGuard {
    address private NEO;
    bytes public baseURI = "https://oca.mypinata.cloud/ipfs/";

    address private The_Dude = 0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b;

    uint8 bgTypeCount = 2;
    uint8 eyesCount = 1;
    uint8 eyeColorCount = 10;
    uint8 gradientColorCount = 22;
    uint8 speciesCount = 4;
    uint8 speciesColorCount = 5;
    uint256 lastTokenId;

    string bgViewBox = "0 0 1280 1280";

    //     bgSvg[0],
    // c1,
    // bgSvg[1],
    // c2,
    // bgSvg[2],
    // generateHead(),
    // bgSvg[3]

    string[2] private bgSvg = [
        "<svg overflow='visible'  xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='",
        "'><style type='text/css'>.hide {animation: showhide 1s ease;opacity:1;}.hide:hover {animation: hideshow .5s ease;opacity:0;}@keyframes hideshow {0% { opacity: 1; }10% { opacity: 0.9; }15% { opacity: 0.7; }30%{opacity:0.5;}100%{opacity:0;}}@keyframes showhide{0%{opacity:0;}10%{opacity:0.2;}15%{opacity:0.4;}30%{opacity:0.6;}100%{opacity: 1;}} </style>"
    ];
    string[] private svg = [
        "<svg x='",
        "' y='",
        "' overflow='visible'>",
        "</svg>"
    ];

    string[] private bgSvgGrad = [
        "<defs><linearGradient id='d' y2='1' x2='0'><stop stop-color='",
        "' offset='0'/><stop stop-color='",
        "' offset='1'/></linearGradient></defs><rect width='100%' height='100%' fill='url(#d)'/>"
    ];

    string[] private bodySvg = [
        "<path transform='matrix(1 0 .001512 1 -1.8639 -196.71)' d='m853.22 1144.8 632.11 213.51h-1264.2l632.11-213.51z' fill='url(#s)' stroke='#000' stroke-width='7' paint-order='stroke'/>"
    ];

    string[] private mouthSVG = [
        "<path d='M502.5 900h298.951v75.869H502.5z' stroke='#000' stroke-width='5' fill='",
        "' />"
    ];

    string[] private headSvg = [
        "<path d='M805-5v810H-5V-5'/><path d='M0 0v800h800V0' fill='url(#s)'/>"
    ];

    string[] private eyeSvg = [
        "<svg fill='",
        "' stroke='#000' stroke-width='4'><path d='M650 500h100v100H650z' fill='#fff'/><path d='m676.7 526.15h45.283v45.283h-45.283z'/><path d='m690.9 539.7h16.898v16.898h-16.898z' fill='#000'/><path d='m1e3 500h100v100h-100z' fill='#fff'/><path d='m1026.7 526.15h45.283v45.283h-45.283z'/><path d='m1040.9 539.7h16.898v16.898h-16.898z' fill='#000'/></svg>"
    ];

    string[] private shirtSVG = [
        "<path d='m1852.4 196.54h230.12v3.455h-230.12z'/><svg fill='",
        "' overflow='visible'><path d='m1874.2 200h95.397l630.42 174.6h-1264.3l516.11-174.6h22.359z'/><path d='m1961.3 200 638.74 174.4-514.61-174.4h-123.13z'/></svg>"
    ];

    string[] private hairSVG = [
        "<defs><linearGradient id='h'><stop stop-color='",
        "'/></linearGradient></defs><path d='M500 500.334h104.4v4.545H500z'/><path d='M599.788783 501.028577v-99.362h4.581v99.362z'/><path d='M599.788 401.664h600.143v4.555H599.788z'/><path d='M1199.931141 401.664008v100h-4.534v-100z'/><path d='M1301.87 505.443h-106.473v-4.559h106.473z'/><path fill='url(#h)' d='M500.145 247.757h799.767v153.711H500.145z' data-bx-origin='0.397 0.801'/><path fill='url(#h)' d='M500.145 401h100v100h-100zm699.767 0h100v100h-100z'/>"
    ];

    string[] private ponyTailSVG = [
        "<defs><linearGradient id='h' ><stop stop-color='",
        "'/></linearGradient></defs><path d='M1300 605.948h-103.62v-5H1300zM500 700h100v4.043H500zm103.9596-199.9996v204.043h-3.959v-204.043zm0-.0015 99.8119-.1033.0042 4.066-99.8119.1033z'/><path d='m700.13 499.9v-99.791h3.64v99.791z'/><path d='m700 400 300 0.105-0.0015 4.307-300-0.105z'/><path d='m1002 400.11v99.895h-4.492v-99.895zm-4.3237 99.898 206.25-0.02 4e-4 4.119-206.25 0.02z'/><path d='m1199.9 499.98 0.4586 100.2-4.001 0.0183-0.4585-100.2z'/><svg fill='url(#h)' overflow='visible'><path d='M500 248h800v153H500z'/><path d='m1e3 400h300v101h-300z'/><path d='M1200 500h100v101.5h-100zM500 400h200v101H500z'/><path d='M500 500h100v200H500z'/><path d='m497.49 1053h175v227h-175z' stroke='#000' stroke-width='6'/></svg>"
    ];

    string[] private eyelidsSVG = [
        "<path d='M650 498h100v26.154H650zm350 0h100v26.154h-100z' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='w' begin='0s;b.end' dur='3.5s' from='0' to='0'/><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -500.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path><svg y='5.9%'><path d='M650 498h100v26.154H650zm350 0h100v26.14h-100z' class='blinkBotto' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -520.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path></svg>"
    ];

    string[] private eyebrowsSVG = [
        "<path d='M650 468h100v21.658H650zm350 0h100v21.658h-100z' fill='url(#h)' stroke='#000' stroke-width='5'/>"
    ];

    string[] private noseSVG = [
        "<path d='m424.37 720.47 75.633 131h-151.27l75.634-131z'  fill-opacity='0.035' stroke='#000' stroke-width='4' data-bx-shape='triangle 348.733 720.474 151.267 131.002 0.5 0 [email protected]'/>"
    ];

    string[] private earSVG = [
        "<defs><linearGradient id='s' ><stop stop-color='",
        "'/></linearGradient></defs><path id='c' d='m428.4 406.29a43.415 43.415 0 1 1 0 43.415 21.809 21.809 0 0 0 0-43.415z' stroke='#000' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]'/><svg width='909.76' height='113.77' fill='url(#s)' viewBox='513.126 535.454 909.759 113.767'><use transform='matrix(-.020544 1.0313 -.9438 -.018801 969.89 130.91)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]' href:href='#c'/><path d='m517.02 541.73h80.115v64.604h-80.115z'/><path d='m513.13 536.52h4.652v70.911h-4.652z' fill='#000'/><path d='m513.4 536.36h86.471v5.369h-86.471z' fill='#000'/><use transform='matrix(.020544 1.0311 .9438 -.03106 966.12 135.93)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]' href:href='#c'/><path d='m1419 540.87-80.115 1.0406v64.604l80.115-1.0406z'/><path d='m1422.9 535.61-4.6516 0.0604v70.911l4.6516-0.0605z' fill='#000'/><path d='m1422.6 535.45-86.471 1.1231v5.3695l86.471-1.1232z' fill='#000'/></svg>"
    ];

    string[] private glassesSVG = [
        "<svg class='hide' fill='",
        "'stroke='#000' stroke-width='4' overflow='visible'><path id='a' d = 'M596.99 343.333a89.677 89.677 0 1 0 179.354 0 89.677 89.677 0 1 0-179.354 0Zm11.715 0a77.962 77.962 0 0 1 155.924 0 77.962 77.962 0 0 1-155.924 0Z' transform = 'matrix(0 1 -1 .006581 980.105379 -107.225916)' /> <use href='#a' transform = 'matrix(0 1.02 -1 .006581 1569.4 -72.789584)' /> <path fill='#000' d = 'M 724.62 558.604 L 725.347 562.943 L 899.897 561.465 L 899.988 558.987' /> <path stroke='none' d = 'M 723.157 573.059 L 717.611 563.6 L 797.188 562.877 L 847.521 563.092 L 902.257 562.955 L 900.21 572.654' /> <path fill='#000' stroke = 'none' d = 'M 725.12 573.169 L 814.429 568.607 L 900.089 572.782 L 899.564 578.436 C 899.564 578.436 902.76 577.146 881.588 576.006 C 866.636 575.201 832.73 573.088 814.588 573.066 C 799.307 573.047 783.958 574.454 770.486 575.385 C 726.313 578.439 726.018 576.404 726.018 576.818' /> <path d='M 1067.375 544.94 L 1214.175 509.35 L 1213.788 509.164 L 1073.393 560.666 M 561.189 538.644 L 556.386 536.943 L 518.62 527.298 L 409.5 501.267 L 414.616 500.766 L 555.071 552.439' /> <svg fill='",
        "' opacity='",
        "%'><circle cx='637' cy='582' r='79'/><circle cx='988' cy='580.5' r='79'/></svg></svg>"
    ];

    //        uint256 svgId;
    //    uint256 colorId;
    //    uint256 varCount;

    //        colorMapping2[0] = 0;
    // svgLayers[_id].attributes[listId] = SVGAttributes(
    //     1,
    //     0,
    //     1,
    //     colorMapping2
    // );

    struct AddAttribute {
        uint32 id;
        string[] svg;
        uint256[] colorMapping;
    }

    struct TokenLayers {
        uint256[] attributes;
        mapping(uint256 => bytes) colors;
    }

    struct TokenRevealInfo {
        bool revealed;
        uint256 seed;
        uint256 season;
        uint256 count;
        mapping(uint256 => TokenLayers) layers;
    }
    struct TokenLayerInfo {
        uint32 layer;
    }

    struct Eyes {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) eyeColors;
    }

    struct Drops {
        bytes ipfsHash;
        bytes ipfsPreview;
        uint16 id;
        uint16 revealStage;
        uint256 snapshot;
    }

    struct Backgrounds {
        mapping(uint256 => bytes32) backgroundType;
        mapping(uint256 => bytes) gradientColors;
    }

    struct Species {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) speciesColors;
    }

    Backgrounds private backgrounds;
    Species private species;
    Eyes private eyes;

    struct GradientBGs {
        bytes color;
    }

    // struct DropInfo {
    //     uint16 id;
    //     uint256 snapshot;
    //     uint256 baseIPFS;
    //     uint256 previewIPFS;
    //     mapping(uint256 => HashInfo) hashes;
    // }

    struct TokenInfo {
        uint16 stage;
        uint256 lastToken;
        uint256 hash;
    }

    struct RevealToken {
        uint8 v;
        uint256 drop;
        uint256 index;
        bytes32 r;
        bytes32 s;
        uint256 tokenId;
    }

    struct SVGInfo {
        bytes name;
        uint256 count;
        mapping(uint256 => SVGLayer) layer;
    }

    struct SVGLayer {
        bool inactive;
        uint256 remaining;
        string x;
        string y;
        string[] svg;
    }

    struct SVGLayers {
        bytes name;
        uint256 layerCount;
        mapping(uint256 => SVGAttributes) attributes;
    }

    struct Colors {
        bytes name;
        uint256 count;
        mapping(uint256 => bytes) list;
    }

    struct SVGAttributes {
        uint256 svgId;
        uint256 colorId;
        uint256 varCount;
        uint256[] colorMapping;
    }

    struct AttributeMapping {
        bytes name;
        uint256 attributeCount;
        mapping(uint256 => Attribute) info;
    }

    struct Attribute {
        mapping(uint256 => bool) isNumber;
        mapping(uint256 => uint256[2]) range;
        bool inactive;
        uint256 remaining;
        uint256 colorId;
        uint256 varCount;
        string x;
        string y;
        string[] svg;
    }

    //     struct SVGInfo {
    //     bytes name;
    //     uint256 count;
    //     mapping(uint256 => SVGLayer) layer;
    // }

    // struct SVGLayer {
    //     bool inactive;
    //     uint256 remaining;
    //     string x;
    //     string y;
    //     string[] svg;
    // }

    // mapping(uint32 => SVGInfo) private svgList;

    mapping(address => uint256) public nonces;
    mapping(uint256 => Drops) private drops;
    mapping(uint256 => TokenRevealInfo) public tokens;

    mapping(uint256 => Colors) private colors;
    mapping(uint256 => SVGLayers) public svgLayers;

    mapping(uint256 => AttributeMapping) public attributes;

    constructor(address _NEO) ERC721G("AIAlbumsMint", "AIA", 0, 10000) {
        // attributes[0].colorId = 0;
        // attributes[0].svgId = 0;

        //        bool isNumber;
        // bool inactive;
        // uint256 remaining;
        // uint256 colorId;
        // uint256 varCount;
        // uint256[2] range;
        // string x;
        // string y;
        // string[] svg;
        attributes[0].name = "Backgrounds";
        attributes[0].attributeCount = 1;
        attributes[0].info[0].varCount = 2;
        attributes[0].info[0].svg = bgSvgGrad;
        svgLayers[0].layerCount = 1;
        attributes[0].info[0].range[0] = [0, 21];
        attributes[0].info[0].range[1] = [0, 21];

        attributes[1].name = "Ears";
        attributes[1].attributeCount = 1;
        attributes[1].info[0].varCount = 1;
        attributes[1].info[0].svg = earSVG;
        attributes[1].info[0].colorId = 1;
        attributes[1].info[0].x = "15.6%";
        attributes[1].info[0].y = "42.5%";
        svgLayers[1].layerCount = 1;

        attributes[2].name = "Head";
        attributes[2].attributeCount = 1;
        attributes[2].info[0].varCount = 0;
        attributes[2].info[0].svg = headSvg;
        attributes[2].info[0].colorId = 1;
        attributes[2].info[0].x = "20%";
        attributes[2].info[0].y = "20%";
        svgLayers[2].layerCount = 1;

        // attributes[12].name = "Glasses";
        // attributes[12].attributeCount = 1;
        // attributes[12].info[0].varCount = 3;
        // attributes[12].info[0].svg = glassesSVG;
        // attributes[12].info[0].colorId = 0;
        // attributes[12].info[0].x = "-12.2%";
        // attributes[12].info[0].y = "3.8%";
        // attributes[12].info[0].range[2] = [75, 98];
        // svgLayers[12].layerCount = 1;
        // attributes[12].info[0].isNumber[2] = true;

        // attributes[3].info[0] = Attribute(
        //     false,
        //     1,
        //     1,
        //     [uint256(0), uint256(0)]
        // );

        // svgLayers[3].layerCount = 1;

        attributes[3].name = "Eyes";
        attributes[3].attributeCount = 1;
        attributes[3].info[0].varCount = 1;
        attributes[3].info[0].svg = eyeSvg;
        attributes[3].info[0].colorId = 5;
        attributes[3].info[0].x = "-17.35%";
        attributes[3].info[0].y = "5.5%";
        svgLayers[3].layerCount = 1;

        attributes[4].name = "Brows";
        attributes[4].attributeCount = 1;
        attributes[4].info[0].varCount = 0;
        attributes[4].info[0].svg = eyebrowsSVG;
        attributes[4].info[0].colorId = 7;
        attributes[4].info[0].x = "-17.35%";
        attributes[4].info[0].y = "5.5%";
        svgLayers[4].layerCount = 1;

        attributes[5].name = "Eye Lids";
        attributes[5].attributeCount = 0;
        attributes[5].info[0].varCount = 0;
        attributes[5].info[0].svg = eyelidsSVG;
        attributes[5].info[0].colorId = 1;
        attributes[5].info[0].x = "-17.35%";
        attributes[5].info[0].y = "5.5%";
        svgLayers[5].layerCount = 1;

        attributes[6].name = "Glasses";
        attributes[6].attributeCount = 1;
        attributes[6].info[0].varCount = 3;
        attributes[6].info[0].svg = glassesSVG;
        attributes[6].info[0].x = "-12.2%";
        attributes[6].info[0].y = "3.8%";
        attributes[6].info[0].range[2] = [75, 98];
        svgLayers[6].layerCount = 1;
        attributes[6].info[0].isNumber[2] = true;
        attributes[6].info[0].range[0] = [22, 30];
        attributes[7].info[0].range[1] = [0, 21];

        attributes[7].name = "Hair";
        attributes[7].attributeCount = 2;
        attributes[7].info[0].varCount = 1;
        attributes[7].info[0].svg = hairSVG;
        attributes[7].info[1].svg = ponyTailSVG;
        attributes[7].info[0].colorId = 7;
        attributes[7].info[1].colorId = 7;
        attributes[7].info[0].x = "-19.065%";
        attributes[7].info[0].y = "0.5%";
        attributes[7].info[1].x = "-19.065%";
        attributes[7].info[1].y = "0.5%";
        svgLayers[7].layerCount = 2;

        attributes[8].name = "Body";
        attributes[8].attributeCount = 1;
        attributes[8].info[0].varCount = 1;
        attributes[8].info[0].svg = bodySvg;
        attributes[8].info[0].colorId = 1;
        attributes[8].info[0].x = "-17.2%";
        attributes[8].info[0].y = "8.9%";
        svgLayers[8].layerCount = 1;

        attributes[9].name = "Mouth";
        attributes[9].attributeCount = 1;
        attributes[9].info[0].varCount = 1;
        attributes[9].info[0].svg = mouthSVG;
        attributes[9].info[0].colorId = 8;
        svgLayers[9].layerCount = 1;

        attributes[10].name = "Shirt";
        attributes[10].attributeCount = 1;
        attributes[10].info[0].varCount = 1;
        attributes[10].info[0].svg = shirtSVG;
        attributes[10].info[0].colorId = 6;
        attributes[10].info[0].x = "-104.3%";
        attributes[10].info[0].y = "70.425%";
        svgLayers[10].layerCount = 1;

        attributes[11].name = "Nose";
        attributes[11].attributeCount = 1;
        attributes[11].info[0].varCount = 0;
        attributes[11].info[0].svg = noseSVG;
        attributes[11].info[0].colorId = 1;
        attributes[11].info[0].x = "18%";
        svgLayers[11].layerCount = 1;

        attributes[12].name = "Earings";
        attributes[12].attributeCount = 1;
        attributes[12].info[0].varCount = 0;
        attributes[12].info[0].colorId = 1;
        attributes[12].info[0].svg = [""];
        attributes[12].info[0].x = "16.9%";
        attributes[12].info[0].y = "47.5%";
        svgLayers[12].layerCount = 1;

        // uint256[] memory colorMapping1 = new uint256[](2);
        // colorMapping1[0] = 0;
        // colorMapping1[1] = 1;
        // uint256[] memory colorMapping2 = new uint256[](1);
        // // colorMapping2[0] = 0;
        // uint256[] memory colorMapping3 = new uint256[](1);

        // uint256[] memory colorMapping5 = new uint256[](0);

        // uint256[] memory colorMapping4 = new uint256[](3);

        // uint256[] memory colorMapping6 = new uint256[](6);

        // svgList[0].count = 1;
        // svgList[0].name = "Backgrounds";
        // svgList[0].layer[0].svg = bgSvgGrad;
        // // svgList[0].list[1] = bgSvgSolid;

        // svgLayers[0].name = "background";
        // svgLayers[0].attributes[0] = SVGAttributes(0, 0, 2, colorMapping1);
        // colorMapping1[1] = 0;

        // svgList[1].count = 1;
        // svgList[1].name = "Ears";
        // svgList[1].layer[0].svg = earSVG;
        // svgList[1].layer[0].x = "15.6%";
        // svgList[1].layer[0].y = "42.5%";
        // svgLayers[1].name = "ears";
        // svgLayers[1].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[2].count = 1;
        // svgList[2].name = "Head";
        // svgList[2].layer[0].svg = headSvg;
        // svgList[2].layer[0].x = "20%";
        // svgList[2].layer[0].y = "20%";
        // svgLayers[2].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // //    svgList[1].layer[0].list[0];
        // // svgLayers[1].name = "head";

        // // svgList[3].count = 1;
        // // svgList[3].name = "Glasses";
        // // svgList[3].layer[0].svg = [""];
        // // svgList[3].layer[0].x = "-19.5%";
        // // svgList[3].layer[0].y = "-0.5%";
        // // svgLayers[3].name = "glasses";
        // // // svgLayers[3].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // // svgLayers[3].attributes[0] = SVGAttributes(0, 0, 3, colorMapping4);

        // svgList[3].count = 2;
        // svgList[3].name = "Hair";
        // svgList[3].layer[0].svg = hairSVG;
        // svgList[3].layer[1].svg = ponyTailSVG;

        // svgList[3].layer[0].x = "-19.065%";
        // svgList[3].layer[0].y = "0.5%";
        // svgList[3].layer[1].x = "-19.065%";
        // svgList[3].layer[1].y = "0.5%";
        // svgLayers[3].name = "hair";
        // svgLayers[3].attributes[0] = SVGAttributes(0, 7, 1, colorMapping3);
        // svgLayers[3].attributes[1] = SVGAttributes(1, 7, 1, colorMapping3);

        // svgList[4].count = 1;
        // svgList[4].name = "Body";
        // svgList[4].layer[0].svg = bodySvg;
        // svgList[4].layer[0].x = "-17.2%";
        // svgList[4].layer[0].y = "8.9%";
        // svgLayers[4].name = "body";
        // svgLayers[4].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[5].count = 1;
        // svgList[5].name = "Eyes";
        // svgList[5].layer[0].svg = eyeSvg;
        // svgList[5].layer[0].x = "-17.35%";
        // svgList[5].layer[0].y = "5.5%";
        // svgLayers[5].name = "eyes";
        // svgLayers[5].attributes[0] = SVGAttributes(0, 5, 1, colorMapping3);

        // svgList[6].count = 1;
        // svgList[6].name = "Mouth";
        // svgList[6].layer[0].svg = mouthSVG;
        // svgLayers[6].name = "mouths";
        // svgLayers[6].attributes[0] = SVGAttributes(0, 8, 1, colorMapping3);

        // svgList[7].count = 1;
        // svgList[7].name = "Shirt";
        // svgList[7].layer[0].svg = shirtSVG;
        // svgList[7].layer[0].x = "-104.3%";
        // svgList[7].layer[0].y = "70.425%";
        // svgLayers[7].name = "shirt";
        // svgLayers[7].attributes[0] = SVGAttributes(0, 6, 1, colorMapping3);

        // svgList[9].count = 1;
        // svgList[9].name = "Eye Lids";
        // svgList[9].layer[0].svg = eyelidsSVG;
        // svgList[9].layer[0].x = "-17.35%";
        // svgList[9].layer[0].y = "5.5%";
        // svgLayers[9].name = "eyelids";
        // svgLayers[9].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[8].count = 1;
        // svgList[8].name = "Brows";
        // svgList[8].layer[0].svg = eyebrowsSVG;
        // svgList[8].layer[0].x = "-17.35%";
        // svgList[8].layer[0].y = "5.5%";
        // svgLayers[8].name = "brows";
        // svgLayers[8].attributes[0] = SVGAttributes(0, 7, 0, colorMapping5);

        // svgList[10].count = 1;
        // svgList[10].name = "Nose";
        // svgList[10].layer[0].svg = noseSVG;
        // svgList[10].layer[0].x = "18%";
        // svgLayers[10].name = "nose";
        // svgLayers[10].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[11].count = 1;
        // svgList[11].name = "Earings";
        // svgList[11].layer[0].svg = ["erk"];
        // svgList[11].layer[0].x = "16.9%";
        // svgList[11].layer[0].y = "47.5%";
        // svgLayers[11].name = "earings";

        //svgLayers[11].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        //<svg x="-87.3%" y="61.5%"

        //make new array with 2 elements

        //        svgLayers[0].attributes[1] = SVGAttributes(1, 0, 1, colorMapping2);

        colors[0].name = "bg";
        colors[0].count = 21;
        colors[0].list[0] = "#FF0000"; //red
        colors[0].list[1] = "#EDB9B9"; //light red (pink)
        colors[0].list[2] = "#8F2323"; //dark red
        colors[0].list[3] = "#FF7F7F"; //pink
        colors[0].list[4] = "#E7E9B9"; //yellow-green
        colors[0].list[5] = "#8F6A23"; //yellow-brown
        colors[0].list[6] = "#737373"; //grey
        colors[0].list[7] = "#FFD400"; //dark-yellow
        colors[0].list[8] = "#B9EDE0"; //pastel blue
        colors[0].list[9] = "#4F8F23"; //dark green
        colors[0].list[10] = "#CCCCCC"; //light grey
        colors[0].list[11] = "#FFFF00"; //yellow
        colors[0].list[12] = "#B9D7ED"; //light blue
        colors[0].list[13] = "#23628F"; // dark cyan
        colors[0].list[14] = "#BFFF00"; //lime green
        colors[0].list[15] = "#DCB9ED"; //light purple
        colors[0].list[16] = "#6B238F"; //dark purple
        colors[0].list[17] = "#6AFF00"; //neon reen
        colors[0].list[18] = "#00EAFF"; //cyan
        colors[0].list[19] = "#0095FF"; //blue
        colors[0].list[20] = "#0040FF"; //dark blue

        //glass rim colors (for glasses)

        colors[0].list[21] = "#000000"; //black
        colors[0].list[22] = "#FFFFFF"; //white
        colors[0].list[23] = "#FF0000"; //red
        colors[0].list[24] = "#FFFF00"; //yellow
        colors[0].list[25] = "#00FF00"; //green
        colors[0].list[26] = "#00FFFF"; //cyan
        colors[0].list[27] = "#0000FF"; //blue
        colors[0].list[28] = "#FF00FF"; //magenta
        colors[0].list[29] = "#FF7F7F"; //pink

        species.name[0] = "Human";
        species.name[1] = "Alien";
        species.name[2] = "Robot";
        species.name[3] = "Nanik";
        species.speciesColors[0] = "#C58C85";
        species.speciesColors[1] = "#ECBCB4";
        species.speciesColors[2] = "#D1A3A4";
        species.speciesColors[3] = "#A1665e";
        species.speciesColors[4] = "#503335";

        colors[4].name = "Nanik";
        colors[4].count = 5;
        colors[4].list[0] = "#C58C85";
        colors[4].list[1] = "#ECBCB4";
        colors[4].list[2] = "#D1A3A4";
        colors[4].list[3] = "#A1665e";
        colors[4].list[4] = "#503335";

        colors[3].name = "Robot";
        colors[3].count = 5;
        colors[3].list[0] = "#C58C85";
        colors[3].list[1] = "#ECBCB4";
        colors[3].list[2] = "#D1A3A4";
        colors[3].list[3] = "#A1665e";
        colors[3].list[4] = "#503335";

        colors[2].name = "Alien";
        colors[2].count = 5;
        colors[2].list[0] = "#C58C85";
        colors[2].list[1] = "#ECBCB4";
        colors[2].list[2] = "#D1A3A4";
        colors[2].list[3] = "#A1665e";
        colors[2].list[4] = "#503335";

        colors[1].name = "humans";
        colors[1].count = 5;
        colors[1].list[0] = "#C58C85";
        colors[1].list[1] = "#ECBCB4";
        colors[1].list[2] = "#D1A3A4";
        colors[1].list[3] = "#A1665e";
        colors[1].list[4] = "#503335";

        colors[8].name = "human-lips";
        colors[8].count = 5;
        colors[8].list[0] = "#D99E96";
        colors[8].list[1] = "#F2C7C2";
        colors[8].list[2] = "#E2B2B0";
        colors[8].list[3] = "#B17F7A";
        colors[8].list[4] = "#5F3F3B";

        colors[9].name = "lipstick";
        colors[9].count = 5;
        colors[9].list[0] = "#E35D6A";
        colors[9].list[1] = "#F7A5B0";
        colors[9].list[2] = "#F28E9B";
        colors[9].list[3] = "#C65E6A";
        colors[9].list[4] = "#6F2F35";

        colors[5].name = "eyes";
        colors[5].count = 10;
        colors[5].list[0] = "#76C4AE";
        colors[5].list[1] = "#9FC2BA";
        colors[5].list[2] = "#BEE9E4";
        colors[5].list[3] = "#7CE0F9";
        colors[5].list[4] = "#CAECCF";
        colors[5].list[5] = "#D3D2B5";
        colors[5].list[6] = "#CABD80";
        colors[5].list[7] = "#E1CEB1";
        colors[5].list[8] = "#DDB0A0";
        colors[5].list[9] = "#D86C70";

        colors[6].name = "shirt";
        colors[6].count = 17;
        colors[6].list[0] = "#FFFBA8";
        colors[6].list[1] = "#693617";
        colors[6].list[2] = "#650C17";
        colors[6].list[3] = "#7BDE4E";
        colors[6].list[4] = "#EB9B54";
        colors[6].list[5] = "#FF5E00";
        colors[6].list[6] = "#202020";
        colors[6].list[7] = "#3E3433";
        colors[6].list[8] = "#FFB300";
        colors[6].list[9] = "#FFCFE7";
        colors[6].list[10] = "#AFAFAF";
        colors[6].list[11] = "#032D49";
        colors[6].list[12] = "#193D24";
        colors[6].list[13] = "#CE051f";
        colors[6].list[14] = "#101C86";
        colors[6].list[15] = "#1BCEfA";
        colors[6].list[16] = "#FFFFFF";

        colors[7].name = "hair";
        colors[7].count = 10;
        colors[7].list[0] = "#AA8866";
        colors[7].list[1] = "#DEBE99";
        colors[7].list[2] = "#241C11";
        colors[7].list[3] = "#4F1A00";
        colors[7].list[4] = "#9A3300";
        colors[7].list[5] = "#505050";
        colors[7].list[6] = "#3264C8";
        colors[7].list[7] = "#FFFF5A";
        colors[7].list[8] = "#DC95DC";
        colors[7].list[9] = "#FE5CAA";

        NEO = _NEO;
        drops[0].id = 0;
        drops[0].snapshot = 0;
        drops[0].ipfsHash = "";
        drops[0].ipfsPreview = "QmcSQvWdTF38norhnXwcGLuCqkqY9Rfty4SfVrfBUNnpGp";

        //loop through and create tokens but low gas
    }

    modifier adminAccess() {
        require(
            msg.sender == NEO ||
                msg.sender == The_Dude ||
                msg.sender == owner(),
            "Admin Access Required"
        );
        _;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _nonce,
        uint256 _drop,
        uint256 _index,
        address _signer
    ) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonce, _drop, _index)
        );
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        require(sender == The_Dude, "Invalid access message.");
        nonces[msg.sender]++;
        _;
    }

    function addAttribute(AddAttribute memory _addAttribute)
        external
        adminAccess
    {
        attributes[_addAttribute.id]
            .info[_addAttribute.colorMapping.length]
            .svg = _addAttribute.svg;
        svgLayers[_addAttribute.id].attributes[
            attributes[_addAttribute.id].attributeCount
        ] = SVGAttributes(
            _addAttribute.colorMapping.length,
            _addAttribute.id,
            _addAttribute.colorMapping.length,
            _addAttribute.colorMapping
        );
        attributes[_addAttribute.id].attributeCount += 1;
    }

    function updateAttribute(
        uint32 id,
        uint32 layerId,
        string[] memory _svg
    ) public adminAccess {
        attributes[id].info[layerId].svg = _svg;
    }

    // function randomSpeciesColor(uint256 _seed)
    //     private
    //     view
    //     returns (bytes memory)
    // {
    //     return
    //         species.speciesColors[
    //             uint256(keccak256(abi.encodePacked(_seed, "speciesColor"))) %
    //                 speciesColorCount
    //         ];
    // }

    // function randomBackgroundType(uint256 _seed)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     return _seed % bgTypeCount;
    // }

    // function generateSVG(uint32 id, uint256 _seed)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     uint256 svgNumber = _seed % svgList[id].count;

    //     uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //     uint32 oddFound = 0;
    //     uint256[] memory colorMapping = svgLayers[id]
    //         .attributes[svgNumber]
    //         .colorMapping;
    //     string[] memory _svg = svgList[id].layer[svgNumber].svg;

    //     //loop through string to create svg with required colors
    //     bytes memory svgBytes = abi.encodePacked(_svg[0]);

    //     bytes[] memory colorsArray = new bytes[](varCount);

    //     for (uint256 i = 1; i < _svg.length + varCount; i++) {
    //         //if odd then color is found
    //         if (i % 2 == 1) {
    //             colorsArray[oddFound] = colors[
    //                 svgLayers[id].attributes[svgNumber].colorId
    //             ].list[
    //                     uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                         colors[id].count
    //                 ];
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 colorsArray[colorMapping[oddFound]]
    //             );
    //             oddFound++;
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, _svg[i - oddFound]);
    //         }
    //     }
    //     if (id != 0) {
    //         svgBytes = abi.encodePacked(
    //             svg[0],
    //             svgList[id].layer[svgNumber].x,
    //             svg[1],
    //             svgList[id].layer[svgNumber].y,
    //             svg[2],
    //             svgBytes,
    //             svg[3]
    //         );
    //     }
    //     return svgBytes;
    // }

    // function generateHead(uint256 _seed) internal view returns (bytes memory) {
    //     return
    //         abi.encodePacked(
    //             headSvg[0],
    //             randomSpeciesColor(_seed),
    //             headSvg[1],
    //             randomEye(69),
    //             headSvg[1],
    //             bodySvg[0],
    //             randomSpeciesColor(_seed),
    //             bodySvg[1]
    //         );
    // }

    // function generateGradientBG(bool isSolid)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     //pick two random colors
    //     uint256 index1 = block.timestamp % gradientColorCount;
    //     uint256 index2 = (block.timestamp + 420) % gradientColorCount;

    //     if (isSolid) index2 = index1;

    //     if (index1 == index2 && !isSolid) {
    //         index2 = (index2 + 1) % gradientColorCount;
    //     }
    //     bytes memory c1 = backgrounds.gradientColors[index1];

    //     bytes memory c2 = backgrounds.gradientColors[index2];

    //     return
    //         abi.encodePacked(
    //             bgSvg[0],
    //             c1,
    //             bgSvg[1],
    //             c2,
    //             bgSvg[2],
    //             generateHead(block.timestamp),
    //             bgSvg[2]
    //         );
    // }

    function singatureClaimHash(
        uint256 _drop,
        uint256 _index,
        uint256 _nonce
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _nonce,
                    _drop,
                    _index
                )
            );
    }

    function mint(address _to, uint32 _amount) public {
        require(msg.sender == NEO, "Admin access only.");
        uint256 _amountToMint = _amount;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(_to, maxBatchSize);
        }
        _mintInternal(_to, _amountToMint);
    }

    function mintTest(address _to, uint32 _amount) public {
        uint256 _amountToMint = _amount;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(_to, maxBatchSize);
        }
        _mintInternal(_to, _amountToMint);
    }

    // set last index to receiver

    //_mint(_to, _amount);

    function randomNumber(uint256 _seed, uint256[2] memory range)
        internal
        pure
        returns (uint256)
    {
        //select random number from range
        uint256 start = range[0];
        uint256 end = range[1];

        uint256 random = (_seed % (end - start + 1)) + start;

        return random;
    }

    //delete random token from array

    //display length of token array to public
    // function getLength() public view returns (uint256) {
    //     return tokenIds.length;
    // }

    // uint8 _v,
    // bytes32 _r,
    // bytes32 _s,
    // uint16 _drop,
    // uint32 _index,
    // uint256 _tokenId

    //  function generateTraits(TokenRevealInfo calldata token) external {}

    // function revealArtTest(RevealToken calldata _revealToken)
    //     external
    // // onlyValidAccess(
    // //     _revealToken.v,
    // //     _revealToken.r,
    // //     _revealToken.s,
    // //     nonces[msg.sender],
    // //     _revealToken.drop,
    // //     _revealToken.index,
    // //     msg.sender
    // // )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];

    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgLayers[i].layerCount;

    //             //create new array of 9 empty

    //             if (i == 7 && svgNumber == 1) {
    //                 female = true;
    //                 // token.count += 1;
    //             }

    //             //attributes[i].info[svgNumber].colorId;

    //             // if (!female && svgNumber == 10) break;

    //             // uint256[] memory colorMapping = attributes[i]
    //             //     .info[svgNumber]
    //             //     .range;

    //             for (
    //                 uint32 j = 0;
    //                 j < attributes[i].info[svgNumber].svg.length - 1;
    //                 j++
    //             ) {
    //                 uint256 start = attributes[i].info[svgNumber].range[j][0];
    //                 uint256 end = attributes[i].info[svgNumber].range[j][1];
    //                 uint256 colorId = attributes[i].info[j].colorId;

    //                 if (end == 0) end = colors[colorId].count;

    //                 if (female && i == 9) {
    //                     colorId++;
    //                 }

    //                 // bytes memory color = colors[colorId].list[
    //                 //     (_seed + j) % colors[colorId].count
    //                 // ];
    //                 //colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colors[colorId].list[
    //                     randomNumber(
    //                         _seed + ((i + 69) * (j + 420)),
    //                         [start, end]
    //                     )
    //                 ];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    function revealArtTest(RevealToken calldata _revealToken)
        external
    // onlyValidAccess(
    //     _revealToken.v,
    //     _revealToken.r,
    //     _revealToken.s,
    //     nonces[msg.sender],
    //     _revealToken.drop,
    //     _revealToken.index,
    //     msg.sender
    // )
    {
        TokenRevealInfo storage token = tokens[_revealToken.tokenId];

        require(_exists(_revealToken.tokenId), "Token does not exist");
        require(!token.revealed, "Token already revealed");

        unchecked {
            // this.generateTraits(token);
            uint256 _seed = block.timestamp + block.difficulty + block.number;

            token.seed = _seed;

            bool female;
            token.count = 12;

            //make new array of bytes

            //generate random traits here and store in token forloop 9 for basic traits

            for (uint32 i = 0; i < 13; i++) {
                uint256 svgNumber = _seed % svgLayers[i].layerCount;

                //create new array of 9 empty

                if (i == 7 && svgNumber == 1) {
                    female = true;
                    // token.count += 1;
                }

                //attributes[i].info[svgNumber].colorId;

                // if (!female && svgNumber == 10) break;

                // uint256[] memory colorMapping = attributes[i]
                //     .info[svgNumber]
                //     .range;

                for (
                    uint32 j = 0;
                    j < attributes[i].info[svgNumber].svg.length - 1;
                    j++
                ) {
                    uint256 start = attributes[i].info[svgNumber].range[j][0];
                    uint256 end = attributes[i].info[svgNumber].range[j][1];
                    uint256 colorId = attributes[i].info[j].colorId;

                    if (end == 0) end = colors[colorId].count;

                    if (female && i == 9) {
                        colorId++;
                    }

                    // bytes memory color = colors[colorId].list[
                    //     (_seed + j) % colors[colorId].count
                    // ];
                    //colorsArray[j] = color;

                    token.layers[i].colors[j] = colors[colorId].list[
                        randomNumber(
                            _seed + ((i + 69) * (j + 420)),
                            [start, end]
                        )
                    ];
                }
                token.revealed = true;
            }

            //  uint32[] memory layers = new uint32[](8);
            // token.layers = new uint32[](10);

            // layers[0] = 0;
            // layers[1] = 1;
            // layers[2] = 2;
            // layers[3] = 3;
            // layers[4] = 4;
            // layers[5] = 5;
            // layers[6] = 6;
            // layers[7] = 8;
            // layers[8] = 8;

            //loop and add 2,1,3,4 layers 1000 times to test size and reveal

            //token.layers = layers;

            //token.layer[0].colors = new uint32[](1);
        }
    }

    // function revealArt(RevealToken calldata _revealToken)
    //     external
    //     onlyValidAccess(
    //         _revealToken.v,
    //         _revealToken.r,
    //         _revealToken.s,
    //         nonces[msg.sender],
    //         _revealToken.drop,
    //         _revealToken.index,
    //         msg.sender
    //     )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];
    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgList[i].count;
    //             uint256 varCount = svgLayers[i].attributes[svgNumber].varCount;

    //             //create new array of 9 empty

    //             if (i == 4 && svgNumber == 1) {
    //                 female = true;
    //                 token.count += 1;
    //             }

    //             if (!female && svgNumber == 12) break;

    //             uint256[] memory colorMapping = svgLayers[i]
    //                 .attributes[svgNumber]
    //                 .colorMapping;
    //             bytes[] memory colorsArray = new bytes[](varCount);
    //             for (uint32 j = 0; j < varCount; j++) {
    //                 uint256 colorId = svgLayers[i].attributes[j].colorId;

    //                 if (female && i == 7) {
    //                     colorId++;
    //                 }

    //                 bytes memory color = colors[colorId].list[
    //                     (_seed + j) % colors[colorId].count
    //                 ];
    //                 colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colorsArray[colorMapping[j]];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    //TODO: create metadata system
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!tokens[_tokenId].revealed) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "animation_url":"',
                                string(
                                    abi.encodePacked(
                                        baseURI,
                                        drops[0].ipfsPreview
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                );
        }

        // uint256 _seed = tokens[_tokenId].seed;

        // uint256 loopCount = tokens[_tokenId].layers.length;

        // //loop through count and generate svg
        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);
        // for (uint256 i = 0; i < loopCount; i++) {
        //     uint32 layer = tokens[_tokenId].layers[i];
        //     _svg = abi.encodePacked(_svg, generateSVG(layer, _seed));
        // }

        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);

        // uint32 layer = tokens[_tokenId].layers[0];

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "animation_url":',
                '"',
                this.recursiveGenerateSVG(
                    abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]),
                    0,
                    _tokenId
                ),
                '</svg>"'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function recursiveGenerateSVG(
        bytes memory svgBytes,
        uint32 id,
        uint256 _tokenId
    ) external view returns (bytes memory) {
        uint256 _seed = tokens[_tokenId].seed;
        uint256 svgNumber = _seed % svgLayers[id].layerCount;

        uint32 oddFound = 0;

        //loop through string to create svg with required colors

        bytes memory newSvg = abi.encodePacked(
            attributes[id].info[svgNumber].svg[0]
        );

        // string[3] private bgSvgGrad = [
        //     '<defs><linearGradient id="d" y2="1" x2="0"><stop stop-color="',
        //     '" offset="0"/><stop stop-color="',
        //     '" offset="1"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#d)"/>'
        // ];

        for (
            uint256 i = 1;
            i < attributes[id].info[svgNumber].svg.length * 2 - 1;
            i++
        ) {
            //if odd then color is found
            if (i % 2 == 1) {
                //check if number or color
                if (attributes[id].info[svgNumber].isNumber[oddFound]) {
                    newSvg = abi.encodePacked(
                        newSvg,
                        Strings.toString(
                            randomNumber(
                                _seed,
                                attributes[id].info[svgNumber].range[oddFound]
                            )
                        )
                    );
                } else
                    newSvg = abi.encodePacked(
                        newSvg,
                        tokens[_tokenId].layers[id].colors[oddFound]
                    );
                oddFound++;
            } else {
                newSvg = abi.encodePacked(
                    newSvg,
                    attributes[id].info[svgNumber].svg[i - oddFound]
                );
            }
        }
        if (id != 0) {
            svgBytes = abi.encodePacked(
                svgBytes,
                svg[0],
                attributes[id].info[svgNumber].x,
                svg[1],
                attributes[id].info[svgNumber].y,
                svg[2],
                newSvg,
                svg[3]
            );
        } else {
            svgBytes = abi.encodePacked(svgBytes, newSvg);
        }

        if (id < tokens[_tokenId].count) {
            return this.recursiveGenerateSVG(svgBytes, id + 1, _tokenId);
        } else return svgBytes;
    }

    // function recursiveGenerateSVG(
    //         bytes memory svgBytes,
    //         uint32 id,
    //         uint256 _tokenId
    //     ) external view returns (bytes memory) {
    //         id = tokens[_tokenId].layers[id];
    //         uint256 _seed = tokens[_tokenId].seed;

    //         uint256 svgNumber = _seed % svgList[id].count;

    //         uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //         uint32 oddFound = 0;

    //         //loop through string to create svg with required colors

    //         bytes[] memory colorsArray = new bytes[](varCount);
    //         bytes memory newSvg = abi.encodePacked(
    //             svgList[id].layer[svgNumber].svg[0]
    //         );
    //         for (
    //             uint256 i = 1;
    //             i < svgList[id].layer[svgNumber].svg.length + varCount;
    //             i++
    //         ) {
    //             //if odd then color is found
    //             if (i % 2 == 1) {
    //                 colorsArray[oddFound] = colors[
    //                     svgLayers[id].attributes[svgNumber].colorId
    //                 ].list[
    //                         uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                             colors[id].count
    //                     ];
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     colorsArray[
    //                         svgLayers[id].attributes[svgNumber].colorMapping[
    //                             oddFound
    //                         ]
    //                     ]
    //                 );
    //                 oddFound++;
    //             } else {
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     svgList[id].layer[svgNumber].svg[i - oddFound]
    //                 );
    //             }
    //         }
    //         if (id != 0) {
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 svg[0],
    //                 svgList[id].layer[svgNumber].x,
    //                 svg[1],
    //                 svgList[id].layer[svgNumber].y,
    //                 svg[2],
    //                 newSvg,
    //                 svg[3]
    //             );
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, newSvg);
    //         }

    //         if (id < tokens[_tokenId].layers.length - 1) {
    //             return this.recursiveGenerateSVG(svgBytes, id + 1, _tokenId);
    //         } else return svgBytes;
    //     }
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
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//★    _______  _____  _______ ___  _____  ★//
//★   / __/ _ \/ ___/ /_  /_  <  / / ___/  ★//
//★  / _// , _/ /__    / / __// / / (_ /   ★//
//★ /___/_/|_|\___/   /_/____/_/  \___/    ★//
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//  by: 0xInuarashi                         //
//////////////////////////////////////////////
//  Audits: 0xAkihiko, 0xFoobar             //
//////////////////////////////////////////////
//  Default: Staking Disabled               //
//////////////////////////////////////////////

contract ERC721G {
    // Standard ERC721 Events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId
    uint256 public immutable startTokenId; // Bytes Storage for the starting TokenId
    uint256 public immutable maxBatchSize;

    // ERC721G Staking Address Target
    function stakingAddress() public view returns (address) {
        return address(this);
    }

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startId_,
        uint256 maxBatchSize_
    ) {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf
        uint32 lastTransfer; // stores the last transfer of the token
        uint32 stakeTimestamp; // stores the stake timestamp in _setStakeTimestamp()
        uint32 totalTimeStaked; // stores the total time staked accumulated
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveall

    // Time Expansion and Compression by 0xInuarashi
    /** @dev Time Expansion and Compression extends the usage of ERC721G from
     *  Year 2106 (end of uint32) to Year 3331 (end of uint32 with time expansion)
     *  the trade-off is that staking accuracy is scoped within 10-second chunks
     */
    function _getBlockTimestampCompressed()
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(block.timestamp / 10);
    }

    function _compressTimestamp(uint256 timestamp_)
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(timestamp_ / 10);
    }

    function _expandTimestamp(uint32 timestamp_)
        public
        view
        virtual
        returns (uint256)
    {
        return uint256(timestamp_) * 10;
    }

    function getLastTransfer(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).lastTransfer);
    }

    function getStakeTimestamp(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).stakeTimestamp);
    }

    function getTotalTimeStaked(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).totalTimeStaked);
    }

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public view virtual returns (uint256) {
        return tokenIndex - startTokenId;
    }

    function balanceOf(address address_) public view virtual returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////

    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     *
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_)
        public
        view
        virtual
        returns (OwnerStruct memory)
    {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");

        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (
            _tokenData[tokenId_].owner != address(0) || tokenId_ >= tokenIndex
        ) {
            return _tokenData[tokenId_];
        }
        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else {
            unchecked {
                uint256 _lowerRange = tokenId_;
                while (mintIndex[_lowerRange].owner == address(0)) {
                    _lowerRange--;
                }
                return mintIndex[_lowerRange];
            }
        }
    }

    /** @dev explanation:
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public view virtual returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return
            _OwnerStruct.stakeTimestamp == 0
                ? _OwnerStruct.owner
                : stakingAddress();
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks.
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_)
        public
        view
        virtual
        returns (address)
    {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////

    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not.
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(
        uint256 tokenId_,
        OwnerStruct memory _OwnerStruct
    ) internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    /** @dev explanation:
     *  _setStakeTimestamp() is our staking / unstaking logic.
     *  If timestamp_ is > 0, the action is "stake"
     *  If timestamp_ is == 0, the action is "unstake"
     *
     *  We grab the tokenData using _getTokenDataOf and then read its values.
     *  As this function requires INITIALIZED tokens only, we call _initializeTokenIf()
     *  to initialize any token using this function first.
     *
     *  Processing of the function is explained in in-line comments.
     */
    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_)
        internal
        virtual
        returns (address)
    {
        // First, call _getTokenDataOf and grab the relevant tokenData
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        // _setStakeTimestamp requires initialization
        _initializeTokenIf(tokenId_, _OwnerStruct);

        // Clear any token approvals
        delete getApproved[tokenId_];

        // if timestamp_ > 0, the action is "stake"
        if (timestamp_ > 0) {
            // Make sure that the token is not staked already
            require(
                _stakeTimestamp == 0,
                "ERC721G: _setStakeTimestamp() already staked"
            );

            // Callbrate balances between staker and stakingAddress
            unchecked {
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }

            // Emit Transfer event from trueOwner
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }
        // if timestamp_ == 0, the action is "unstake"
        else {
            // Make sure the token is not staked
            require(
                _stakeTimestamp != 0,
                "ERC721G: _setStakeTimestamp() already unstaked"
            );

            // Callibrate balances between stakingAddress and staker
            unchecked {
                _balanceData[_owner].balance++;
                _balanceData[stakingAddress()].balance--;
            }

            // we add total time staked to the token on unstake
            uint32 _timeStaked = _getBlockTimestampCompressed() -
                _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;

            // Emit Transfer event to trueOwner
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        // Set the stakeTimestamp to timestamp_
        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        // We save internal gas by returning the owner for a follow-up function
        return _owner;
    }

    /** @dev explanation:
     *  _stake() works like an extended function of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the staking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _stake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to block.timestamp and return the owner
        return _setStakeTimestamp(tokenId_, block.timestamp);
    }

    /** @dev explanation:
     *  _unstake() works like an extended unction of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the unstaking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _unstake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to 0 and return the owner
        return _setStakeTimestamp(tokenId_, 0);
    }

    /** @dev explanation:
     *  _mintAndStakeInternal() is the internal mintAndStake function that is called
     *  to mintAndStake tokens to users.
     *
     *  It populates mintIndex with the phantom-mint data (owner, lastTransferTime)
     *  as well as the phantom-stake data (stakeTimestamp)
     *
     *  Then, it emits the necessary phantom events to replicate the behavior as canon.
     *
     *  Further logic explained in in-line comments.
     */
    function _mintAndStakeInternal(address to_, uint256 amount_)
        internal
        virtual
    {
        // we cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintAndStakeInternal to 0x0");

        // we limit max mints per SSTORE to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintAndStakeInternal over maxBatchSize"
        );

        // process the required variables to write to mintIndex
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;
        uint32 _currentTime = _getBlockTimestampCompressed();

        // write to the mintIndex to store the OwnerStruct for uninitialized tokenData
        mintIndex[_startId] = OwnerStruct(
            to_, // the address the token is minted to
            _currentTime, // the last transfer time
            _currentTime, // the curent time of staking
            0 // the accumulated time staked
        );

        unchecked {
            // we add the balance to the stakingAddress through our staking logic
            _balanceData[stakingAddress()].balance += uint32(amount_);

            // we add the mintedAmount to the to_ through our minting logic
            _balanceData[to_].mintedAmount += uint32(amount_);

            // emit phantom mint to to_, then emit a staking transfer
            do {
                emit Transfer(address(0), to_, _startId);
                emit Transfer(to_, stakingAddress(), _startId);
            } while (++_startId < _endId);
        }

        // set the new tokenIndex to the _endId
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mintAndStake() calls _mintAndStakeInternal() but calls it using a while-loop
     *  based on the required minting amount to stay within the bounds of
     *  max mints per batch (maxBatchSize)
     */
    function _mintAndStake(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintAndStakeInternal(to_, maxBatchSize);
        }
        _mintAndStakeInternal(to_, _amountToMint);
    }

    ///// ERC721G Range-Based Internal Minting Logic /////

    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic.
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintInternal over maxBatchSize"
        );

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        mintIndex[_startId].owner = to_;
        mintIndex[_startId].lastTransfer = _getBlockTimestampCompressed();

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked {
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do {
                emit Transfer(address(0), to_, _startId);
            } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     *
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *
     *  this results in INITIALIZATION of the token, if it has not been initialized yet.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

        // update the balance data
        unchecked {
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    ///// Note: You may implement your own staking functionality     /////
    /////       by using _stake() and _unstake() functions instead   /////
    /////       These are merely out-of-the-box standard functions   /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev clarification:
    //  *  As a developer, you DO NOT have to enable these functions, or use them
    //  *  in the way defined in this section.
    //  *
    //  *  The functions in this section are just out-of-the-box plug-and-play staking
    //  *  which is enabled IMMEDIATELY.
    //  *  (As well as some useful view-functions)
    //  *
    //  *  You can choose to call the internal staking functions yourself, to create
    //  *  custom staking logic based on the section (n-2) above.
    //  */
    // /** @dev explanation:
    // *  this is a staking function that receives calldata tokenIds_ array
    // *  and loops to call internal _stake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    // function stake(uint256[] calldata tokenIds_) public virtual {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     while (i < l) {
    //         // stake and return the owner's address
    //         address _owner = _stake(tokenIds_[i]);
    //         // make sure the msg.sender is the owner
    //         require(msg.sender == _owner, "You are not the owner!");
    //         unchecked {++i;}
    //     }
    // }
    // /** @dev explanation:
    // *  this is an unstaking function that receives calldata tokenIds_ array
    // *  and loops to call internal _unstake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    // function unstake(uint256[] calldata tokenIds_) public virtual {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     while (i < l) {
    //         // unstake and return the owner's address
    //         address _owner = _unstake(tokenIds_[i]);
    //         // make sure the msg.sender is the owner
    //         require(msg.sender == _owner, "You are not the owner!");
    //         unchecked {++i;}
    //     }
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    /////      ERC721G: User-Enabled Staking Helper Functions        /////
    /////      Note: You MUST enable staking functionality           /////
    /////            To make use of these functions below            /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev explanation:
    //  *  balanceOfStaked loops through the entire tokens using
    //  *  startTokenId as the start pointer, and
    //  *  tokenIndex (current-next tokenId) as the end pointer
    //  *
    //  *  it checks if the _trueOwnerOf() is the address_ or not
    //  *  and if the owner() is not the address, indicating the
    //  *  state that the token is staked.
    //  *
    //  *  if so, it increases the balance. after the loop, it returns the balance.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function balanceOfStaked(address address_) public virtual view
    // returns (uint256) {
    //     uint256 _balance;
    //     uint256 i = startTokenId;
    //     uint256 max = tokenIndex;
    //     while (i < max) {
    //         if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
    //             _balance++;
    //         }
    //         unchecked { ++i; }
    //     }
    //     return _balance;
    // }
    // /** @dev explanation:
    //  *  walletOfOwnerStaked calls balanceOfStaked to get the staked
    //  *  balance of a user. Afterwards, it runs staked-checking logic
    //  *  to figure out the tokenIds that the user has staked
    //  *  and then returns it in walletOfOwner fashion.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function walletOfOwnerStaked(address address_) public virtual view
    // returns (uint256[] memory) {
    //     uint256 _balance = balanceOfStaked(address_);
    //     uint256[] memory _tokens = new uint256[] (_balance);
    //     uint256 _currentIndex;
    //     uint256 i = startTokenId;
    //     while (_currentIndex < _balance) {
    //         if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
    //             _tokens[_currentIndex++] = i;
    //         }
    //         unchecked { ++i; }
    //     }
    //     return _tokens;
    // }
    // /** @dev explanation:
    //  *  balanceOf of the address returns UNSTAKED tokens only.
    //  *  to get the total balance of the user containing both STAKED and UNSTAKED tokens,
    //  *  we use this function.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function totalBalanceOf(address address_) public virtual view returns (uint256) {
    //     return balanceOf(address_) + balanceOfStaked(address_);
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfToken returns the accumulative total time staked of a tokenId
    //  *  it reads from the totalTimeStaked of the tokenId_ and adds it with
    //  *  a calculation of pending time staked and returns the sum of both values.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes.
    //  */
    // function totalTimeStakedOfToken(uint256 tokenId_) public virtual view
    // returns (uint256) {
    //     OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
    //     uint256 _totalTimeStakedOnToken = _expandTimestamp(_OwnerStruct.totalTimeStaked);
    //     uint256 _totalTimeStakedPending =
    //         _OwnerStruct.stakeTimestamp > 0 ?
    //         _expandTimestamp(
    //             _getBlockTimestampCompressed() - _OwnerStruct.stakeTimestamp) :
    //             0;
    //     return _totalTimeStakedOnToken + _totalTimeStakedPending;
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfTokens just returns an array of totalTimeStakedOfToken
    //  *  based on tokenIds_ calldata.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes... however
    //  *  BE CAREFUL and USE IT CORRECTLY.
    //  *  (dont pass in 5000 tokenIds_ in a write function)
    //  */
    // function totalTimeStakedOfTokens(uint256[] calldata tokenIds_) public
    // virtual view returns (uint256[] memory) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     uint256[] memory _totalTimeStakeds = new uint256[] (l);
    //     while (i < l) {
    //         _totalTimeStakeds[i] = totalTimeStakedOfToken(tokenIds_[i]);
    //         unchecked { ++i; }
    //     }
    //     return _totalTimeStakeds;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Staking Helper Functions             /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    ///// Note: You do not need to enable these. It makes querying   /////
    /////       things cheaper in GAS at around 1.5k per token       /////
    ////        if you choose to query things as such                /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using ownerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (ownerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using _trueOwnerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isTrueOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (_trueOwnerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        address _owner = ownerOf(tokenId_);
        return (// "i am the owner of the token, and i am transferring it"
        _owner == spender_ ||
            // "the token's approved spender is me"
            getApproved[tokenId_] == spender_ ||
            // "the owner has approved me to spend all his tokens"
            isApprovedForAll[_owner][spender_]);
    }

    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender ||
                // "i am isApprovedForAll, so i can approve this token too."
                isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
    {
        // this function can only be used as self-approvalforall for others.
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized"
        );
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from_,
                    tokenId_,
                    data_
                )
            );
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(
                _selector == 0x150b7a02,
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!"
            );
        }
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function supportsInterface(bytes4 iid_) public view virtual returns (bool) {
        return
            iid_ == 0x01ffc9a7 ||
            iid_ == 0x80ac58cd ||
            iid_ == 0x5b5e139f ||
            iid_ == 0x7f5828d0;
    }

    /** @dev description: walletOfOwner to query an array of wallet's
     *  owned tokens. A view-intensive alternative ERC721Enumerable function.
     */
    function walletOfOwner(address address_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) {
                _tokens[_currentIndex++] = i;
            }
            unchecked {
                ++i;
            }
        }
        return _tokens;
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////

    /** @dev requirement: You MUST implement your own tokenURI logic here
     *  recommended to use through an override function in your main contract.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {}
}
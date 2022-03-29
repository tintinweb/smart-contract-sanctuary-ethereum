// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract IMainNFT {
    
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
    function mintTo(uint256 amount, address _to) external {}
    function maxMintPerTransaction() public returns (uint256) {}
}

contract ThirdTestTicketsPreSale is Ownable {
    using ECDSA for bytes32;
    IMainNFT public immutable mainNFT;
    /** 
     * @dev MINT DATA 
     */
    uint256 public maxVIPSupply = 5;
    uint256 public maxEliteSupply = 5;
    uint256 public boughtVIP = 1;
    uint256 public boughtElite = 1;

    uint256 public vipPrice = 0.0015 ether;
    uint256 public elitePrice = 0.002 ether;

    uint256 public vipStartTime = 1648573503;
    uint256 public vipDuration = 5 minutes;
    uint256 public eliteStartTime = 1648573803;
    uint256 public eliteDuration = 5 minutes;

    uint256 public maxPublicSupply = 5;
    uint256 public boughtPublic = 1;
    uint256 public limitPublic = 2;
    uint256 public publicPrice = 0.004 ether;
    uint256 public startTimePublic = 1648574103;
    
    mapping(address => uint256) public addressToVIPPass;
    mapping(address => uint256) public addressToVIPMints;
    mapping(address => uint256) public addressToEliteMints;
    mapping(address => uint256) public addressToPublicMints;
    /**
     * @dev GIVEAWAY 
     */
    uint256 public maxGiveawaySupply = 3;
    uint256 public giveAwayClaimed = 1;
    mapping(address => uint256) public addressToGiveawayClaimed;

    /**
     * @dev Events
     */
    event ReceivedEther(address indexed sender, uint256 indexed amount);
    event BuyVIPPass(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event EliteMint(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event PublicMint(address indexed buyer, uint256 indexed amount, bool indexed permissioned);
    event vipMint(address indexed redeemer, uint256 amount);
    event ClaimedGiveAway(address indexed redeemer, uint256 amount);
    event SetMaxVIPSupplyEvent(uint256 indexed maxVIPSupply);
    event SetMaxEliteSupplyEvent(uint256 indexed maxEliteSupply);
    event SetMaxPublicSupplyEvent(uint256 indexed maxSupply);
    event SetLimitPublicEvent(uint256 indexed limit);
    event SetPricePublicEvent(uint256 indexed price);
    event SetGiveAwayMaxSupplyEvent(uint256 indexed newSupply);
    event SetVIPPriceEvent(uint256 indexed price);
    event SetElitePriceEvent(uint256 indexed price);
    event SetVIPStartTimeEvent(uint256 indexed time);
    event SetVIPDurationEvent(uint256 indexed time);
    event SetEliteStartTimeEvent(uint256 indexed time);
    event SetEliteDurationEvent(uint256 indexed time);
    event SetPublicStartTimeEvent(uint256 indexed time);
    event WithdrawEvent(address indexed to, uint256 amount);

    constructor(
        address _mainNFTAddress
    ) Ownable() {
        mainNFT = IMainNFT(_mainNFTAddress);
    }


    function getPublicPrice() public view returns (uint256) {
        uint256 _price = publicPrice;
        if (block.timestamp >= startTimePublic) {
            _price = publicPrice;
        }if (block.timestamp >= startTimePublic + 5 minutes) {
             _price = _price - 0.001 ether; //0.003 ETH
        }if (block.timestamp >= startTimePublic + 5 minutes) {
             _price = _price - 0.001 ether; //0.002 ETH
        }
        return _price;
    }


    function validatePhaseSpecificPurchase(uint256 amount, uint256 phase) internal {
        if (phase == 1) {
            require(block.timestamp > vipStartTime, "VIP SALE HASN'T STARTED YET");
            require(block.timestamp < vipStartTime + vipDuration, "VIP SALE IS CLOSED");    
            require(msg.value == vipPrice * amount , "ETHER SENT NOT CORRECT");
            require(boughtVIP + amount - 1 <= maxVIPSupply, "BUY AMOUNT GOES OVER MAX SUPPLY");

        } else if (phase == 2) {
            require(block.timestamp >= eliteStartTime, "ELITE SALE HASN'T STARTED YET");
            require(block.timestamp < eliteStartTime + eliteDuration, "ELITE SALE IS CLOSED");    
            require(msg.value == elitePrice * amount, "ETHER SENT NOT CORRECT");
            require(boughtElite + amount - 1 <= maxEliteSupply, "BUY AMOUNT GOES OVER MAX SUPPLY");

        } else {
            revert("INCORRECT PHASE");
        }
    }

    /**
     * 
     * add 1 to buMaxamount to validate msg.sender + amount < without using <= to save gas
     */
    function buyVIPPass(uint256 amount, uint256 buyMaxAmount, uint256 phase, bytes calldata signature) 
        external 
        payable {

        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All mint data is embedded in the merkle proof.
        /// @dev Verify that user can perform permissioned sale based on the provided parameters.
        require(address(mainNFT) != address(0), "MAIN NFT SMART CONTRACT NOT SET");
        require(phase > 0 && phase < 3, "INCORRECT PHASE SUPPLIED");
        require(owner() ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature), "ADDRESS IS NOT PERMISSIONED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        /// @dev verify that user can perform permissioned sale based on phase of user
        validatePhaseSpecificPurchase(amount, phase);

        /// @dev update pre-sales and whale-sales seperately
        if (phase == 1) {
            boughtVIP += amount;
            require(addressToVIPPass[msg.sender] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");                      
            addressToVIPPass[msg.sender] += amount;
            emit BuyVIPPass(msg.sender, boughtVIP, true);
        }            
        else if (phase == 2) {   
            boughtElite += amount;
            require(addressToEliteMints[msg.sender] + amount <= buyMaxAmount, "BUY AMOUNT EXCEEDS MAX FOR USER");     
            addressToEliteMints[msg.sender] += amount;                          
            mainNFT.mintTo(boughtElite, msg.sender);
            emit EliteMint(msg.sender, boughtElite, true);
        }            
    }

    /**
     * @notice Function to buy one or more tickets.
     *
     * @param amount. The amount of tickets to buy.
     */
    function publicMint(uint256 amount) external payable {
        require(block.timestamp >= startTimePublic, "OPEN SALE CLOSED");
        require(amount > 0, "HAVE TO BUY AT LEAST 1");
        require(addressToPublicMints[msg.sender] + amount <= limitPublic, "BUY AMOUNT EXCEEDS MAX FOR USER");
        require(boughtPublic + amount <= maxPublicSupply, "BUY AMOUNT GOES OVER MAX SUPPLY");
        require(msg.value == getPublicPrice() * amount, "ETHER SENT NOT CORRECT");
        boughtPublic += amount;
        addressToPublicMints[msg.sender] += amount;
        mainNFT.mintTo(boughtPublic, msg.sender);
        emit PublicMint(msg.sender, amount, false);
    }

    /**
     * @dev MINTING 
     */

    /**
     * @notice Allows users to claim their tickets for NFTs.
     *
     */
    function VIPMint() external {
        uint256 ticketsOfSender = 
            addressToVIPPass[msg.sender];
        uint256 mintsOfSender = addressToVIPMints[msg.sender];
        uint256 mintable = ticketsOfSender - mintsOfSender;

        require(mintable > 0, "NO MINTABLE PASS");

        uint256 maxMintPerTx = mainNFT.maxMintPerTransaction();
        uint256 toMint = mintable > maxMintPerTx ? maxMintPerTx : mintable;
        
        addressToVIPMints[msg.sender] = addressToVIPMints[msg.sender] + toMint;

        mainNFT.mintTo(toMint, msg.sender);
        emit vipMint(msg.sender, toMint);
    }

    /**
     * @notice Function to claim giveaway.
     * @dev First the Merkle Proof is verified.
     * Then the claim is verified with the data embedded in the Merkle Proof.
     * Finally the juniors are minted to the user's wallet.
     *
     */
    function claimGiveAway(uint256 claimAmount, bytes calldata signature) external {
        /// @dev Verifies Merkle Proof submitted by user.
        /// @dev All giveaway data is embedded in the merkle proof.
        require(owner() ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature), "ADDRESS IS NOT PERMISSIONED");


        /// @dev Verifies that user can perform giveaway based on the provided parameters.

        require(address(mainNFT) != address(0), "MAINT NFT SMART CONTRACT NOT SET");

        require(claimAmount > 0, "HAVE TO CLAIM AT LEAST 1");

        require(addressToGiveawayClaimed[msg.sender] == 0, "GIVEAWAY ALREADY CLAIMED");
        require(giveAwayClaimed + claimAmount <= maxGiveawaySupply, "GIVEAWAY AMOUNT GOES OVER MAX SUPPLY");

        /// @dev Updates contract variables and mints `redeemAmount` juniors to users wallet

        giveAwayClaimed += claimAmount;
        addressToGiveawayClaimed[msg.sender] = 1;

        mainNFT.mintTo(claimAmount, msg.sender);
        emit ClaimedGiveAway(msg.sender, claimAmount);
    }

    /** 
     * @dev OWNER ONLY 
     */

    /**
     * @notice Change the maximum supply of tickets that are for sale in permissioned sale.
     *
     * 
     */
    function setMaxVIPSupply(uint256 newMaxVIPSupply) external onlyOwner {
        maxVIPSupply = newMaxVIPSupply;
        emit SetMaxVIPSupplyEvent(newMaxVIPSupply);
    }

    function setMaxWlSupply(uint256 newMaxEliteSupply) external onlyOwner {
        maxEliteSupply = newMaxEliteSupply;
        emit SetMaxEliteSupplyEvent(newMaxEliteSupply);
    }

    /**
     * @notice Change the maximum supply of tickets that are for sale in open sale.
     *
     */
    function setMaxSupplyPublic(uint256 newMaxPublicSupply) external onlyOwner {
        maxPublicSupply = newMaxPublicSupply;
        emit SetMaxPublicSupplyEvent(newMaxPublicSupply);
    }

    /**
     * @notice Change the limit of tickets per wallet in open sale.
     *
     * @param newLimitPublic. The new max supply.
     */
    function setLimitPublic(uint256 newLimitPublic) external onlyOwner {
        limitPublic = newLimitPublic;
        emit SetLimitPublicEvent(newLimitPublic);
    }

    /**
     * @notice Change the price of tickets that are for sale in open sale.
     *
     * @param newPricePublic. The new price.
     */
    function setPricePublic(uint256 newPricePublic) external onlyOwner {
        publicPrice = newPricePublic;
        emit SetPricePublicEvent(newPricePublic);
    }

    /**
     * @notice Change the price of tickets that are for sale in permissioned sale.
     *
     */
    function setVIPPrice(uint256 newVIPPrice) external onlyOwner {
        vipPrice = newVIPPrice;
        emit SetVIPPriceEvent(newVIPPrice);
    }

        function setElitePrice(uint256 newElitePrice) external onlyOwner {
        elitePrice = newElitePrice;
        emit SetElitePriceEvent(newElitePrice);
    }

    /**
     * @notice Change the merkleRoot of the giveaway.
     *
     * @param newRoot. The new merkleRoot.
     */

    /**
     * @notice Change the max supply for the giveaway.
     *
     * @param newSupply. The new giveaway max supply.
     */
    function setGiveAwayMaxSupply(uint256 newSupply) external onlyOwner {
        maxGiveawaySupply = newSupply;
        emit SetGiveAwayMaxSupplyEvent(newSupply);
    }    

    /**
     * @notice Change start time of the Phase One permissioned sale.
     *
     
     */
    function setVIPStartTime(uint256 newVIPTime) external onlyOwner {
        vipStartTime = newVIPTime;
        emit SetVIPStartTimeEvent(newVIPTime);
    }

    /**
     * @notice Change duration of the Phase One permissioned sale.
     *
     
     */
    function setVIPDuration(uint256 newVIPDuration) external onlyOwner {
        vipDuration = newVIPDuration;
        emit SetVIPDurationEvent(newVIPDuration);
    }

    /**
     * @notice Change start time of the Phase Two permissioned sale.
     *
     
     */
    function setEliteStartTime(uint256 newEliteTime) external onlyOwner {
        eliteStartTime = newEliteTime;
        emit SetEliteStartTimeEvent(newEliteTime);
    }

    /**
     * @notice Change duration of the Phase One permissioned sale.
     *
    
     */
    function setEliteDuration(uint256 newEliteDuration) external onlyOwner {
        eliteDuration = newEliteDuration;
        emit SetEliteDurationEvent(newEliteDuration);
    }

    /**
     * @notice Change start time of the open sale.
     *
     */
    function setPublicStartTime(uint256 newPublicTime) external onlyOwner {
        startTimePublic = newPublicTime;
        emit SetPublicStartTimeEvent(newPublicTime);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale.
     *
     * @param _to. The address to send the funds to.
     */
    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
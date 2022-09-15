/*

  << Project Wyvern Token (WYV) >>

*/

pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

import "./token/UTXORedeemableToken.sol";
import "./token/DelayedReleaseToken.sol";

/**
  * @title WyvernToken
  * @author Project Wyvern Developers
  */
contract WyvernToken is DelayedReleaseToken, UTXORedeemableToken, BurnableToken {

    uint constant public decimals     = 18;
    string constant public name       = "Project Wyvern Token";
    string constant public symbol     = "WYV";

    /* Amount of tokens per Wyvern. */
    uint constant public MULTIPLIER       = 1;

    /* Constant for conversion from satoshis to tokens. */
    uint constant public SATS_TO_TOKENS   = MULTIPLIER * (10 ** decimals) / (10 ** 8);

    /* Total mint amount, in tokens (will be reached when all UTXOs are redeemed). */
    uint constant public MINT_AMOUNT      = 2000000 * MULTIPLIER * (10 ** decimals);

    /**
      * @dev Initialize the Wyvern token
      * @param merkleRoot Merkle tree root of the UTXO set
      * @param totalUtxoAmount Total satoshis of the UTXO set
      */
    constructor (bytes32 merkleRoot, uint totalUtxoAmount) public {
        /* Total number of tokens that can be redeemed from UTXOs. */
        uint utxoTokens = SATS_TO_TOKENS * totalUtxoAmount;

        /* Configure DelayedReleaseToken. */
        temporaryAdmin = msg.sender;
        numberOfDelayedTokens = MINT_AMOUNT - utxoTokens;

        /* Configure UTXORedeemableToken. */
        rootUTXOMerkleTreeHash = merkleRoot;
        totalSupply_ = MINT_AMOUNT;
        maximumRedeemable = utxoTokens;
        multiplier = SATS_TO_TOKENS;
    }

}

/*

  Delayed release token - a token which delays initial mint of a specified amount to allow an address to be provided after the token contract is instantiated.

  Used in our case to allow the Wyvern token to be instantiated, then the Wyvern DAO instantiated using the Wyvern token as the share token, then an amount of WYV to be minted to the DAO.

*/

pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

/**
  * @title DelayedReleaseToken
  * @author Project Wyvern Developers
  */
contract DelayedReleaseToken is StandardToken {

    /* Temporary administrator address, only used for the initial token release, must be initialized by token constructor. */
    address temporaryAdmin;

    /* Whether or not the delayed token release has occurred. */
    bool hasBeenReleased = false;

    /* Number of tokens to be released, must be initialized by token constructor. */
    uint numberOfDelayedTokens;

    /* Event for convenience. */
    event TokensReleased(address destination, uint numberOfTokens);

    /**
     * @dev Release the previously specified amount of tokens to the provided address
     * @param destination Address for which tokens will be released (minted) 
     */
    function releaseTokens(address destination) public {
        require((msg.sender == temporaryAdmin) && (!hasBeenReleased));
        hasBeenReleased = true;
        balances[destination] = numberOfDelayedTokens;
        emit Transfer(address(0), destination, numberOfDelayedTokens); 
        emit TokensReleased(destination, numberOfDelayedTokens);
    }

}

/*

  UTXO redeemable token.

  This is a token extension to allow porting a Bitcoin or Bitcoin-fork sourced UTXO set to an ERC20 token through redemption of individual UTXOs in the token contract.
    
  Owners of UTXOs in a chosen final set (where "owner" is simply anyone who could have spent the UTXO) are allowed to redeem (mint) a number of tokens proportional to the satoshi amount of the UTXO.

  Notes

    - This method *does not* provision for special Bitcoin scripts (e.g. multisig addresses).
    - Pending transactions are public, so the UTXO redemption transaction must work *only* for an Ethereum address belonging to the same person who owns the UTXO.
      This is enforced by requiring that the redeeemer sign their Ethereum address with their Bitcoin (original-chain) private key.
    - We cannot simply store the UTXO set, as that would be far too expensive. Instead we compute a Merkle tree for the entire UTXO set at the chain state which is to be ported,
      store only the root of that Merkle tree, and require UTXO claimants prove that the UTXO they wish to claim is present in the tree.

*/

pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/MerkleProof.sol";

/**
  * @title UTXORedeemableToken
  * @author Project Wyvern Developers
  */
contract UTXORedeemableToken is StandardToken {

    /* Root hash of the UTXO Merkle tree, must be initialized by token constructor. */
    bytes32 public rootUTXOMerkleTreeHash;

    /* Redeemed UTXOs. */
    mapping(bytes32 => bool) redeemedUTXOs;

    /* Multiplier - tokens per Satoshi, must be initialized by token constructor. */
    uint public multiplier;

    /* Total tokens redeemed so far. */
    uint public totalRedeemed = 0;

    /* Maximum redeemable tokens, must be initialized by token constructor. */
    uint public maximumRedeemable;

    /* Redemption event, containing all relevant data for later analysis if desired. */
    event UTXORedeemed(bytes32 txid, uint8 outputIndex, uint satoshis, bytes32[] proof, bytes pubKey, uint8 v, bytes32 r, bytes32 s, address indexed redeemer, uint numberOfTokens);

    /**
     * @dev Extract a bytes32 subarray from an arbitrary length bytes array.
     * @param data Bytes array from which to extract the subarray
     * @param pos Starting position from which to copy
     * @return Extracted length 32 byte array
     */
    function extract(bytes data, uint pos) private pure returns (bytes32 result) { 
        for (uint i = 0; i < 32; i++) {
            result ^= (bytes32(0xff00000000000000000000000000000000000000000000000000000000000000) & data[i + pos]) >> (i * 8);
        }
        return result;
    }
    
    /**
     * @dev Validate that a provided ECSDA signature was signed by the specified address
     * @param hash Hash of signed data
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @param expected Address claiming to have created this signature
     * @return Whether or not the signature was valid
     */
    function validateSignature (bytes32 hash, uint8 v, bytes32 r, bytes32 s, address expected) public pure returns (bool) {
        return ecrecover(hash, v, r, s) == expected;
    }

    /**
     * @dev Validate that the hash of a provided address was signed by the ECDSA public key associated with the specified Ethereum address
     * @param addr Address signed
     * @param pubKey Uncompressed ECDSA public key claiming to have created this signature
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @return Whether or not the signature was valid
     */
    function ecdsaVerify (address addr, bytes pubKey, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
        return validateSignature(sha256(addr), v, r, s, pubKeyToEthereumAddress(pubKey));
    }

    /**
     * @dev Convert an uncompressed ECDSA public key into an Ethereum address
     * @param pubKey Uncompressed ECDSA public key to convert
     * @return Ethereum address generated from the ECDSA public key
     */
    function pubKeyToEthereumAddress (bytes pubKey) public pure returns (address) {
        return address(uint(keccak256(pubKey)) & 0x000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /**
     * @dev Calculate the Bitcoin-style address associated with an ECDSA public key
     * @param pubKey ECDSA public key to convert
     * @param isCompressed Whether or not the Bitcoin address was generated from a compressed key
     * @return Raw Bitcoin address (no base58-check encoding)
     */
    function pubKeyToBitcoinAddress(bytes pubKey, bool isCompressed) public pure returns (bytes20) {
        /* Helpful references:
           - https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses 
           - https://github.com/cryptocoinjs/ecurve/blob/master/lib/point.js
        */

        /* x coordinate - first 32 bytes of public key */
        uint x = uint(extract(pubKey, 0));
        /* y coordinate - second 32 bytes of public key */
        uint y = uint(extract(pubKey, 32)); 
        uint8 startingByte;
        if (isCompressed) {
            /* Hash the compressed public key format. */
            startingByte = y % 2 == 0 ? 0x02 : 0x03;
            return ripemd160(sha256(startingByte, x));
        } else {
            /* Hash the uncompressed public key format. */
            startingByte = 0x04;
            return ripemd160(sha256(startingByte, x, y));
        }
    }

    /**
     * @dev Verify a Merkle proof using the UTXO Merkle tree
     * @param proof Generated Merkle tree proof
     * @param merkleLeafHash Hash asserted to be present in the Merkle tree
     * @return Whether or not the proof is valid
     */
    function verifyProof(bytes32[] proof, bytes32 merkleLeafHash) public view returns (bool) {
        return MerkleProof.verifyProof(proof, rootUTXOMerkleTreeHash, merkleLeafHash);
    }

    /**
     * @dev Convenience helper function to check if a UTXO can be redeemed
     * @param txid Transaction hash
     * @param originalAddress Raw Bitcoin address (no base58-check encoding)
     * @param outputIndex Output index of UTXO
     * @param satoshis Amount of UTXO in satoshis
     * @param proof Merkle tree proof
     * @return Whether or not the UTXO can be redeemed
     */
    function canRedeemUTXO(bytes32 txid, bytes20 originalAddress, uint8 outputIndex, uint satoshis, bytes32[] proof) public view returns (bool) {
        /* Calculate the hash of the Merkle leaf associated with this UTXO. */
        bytes32 merkleLeafHash = keccak256(txid, originalAddress, outputIndex, satoshis);
    
        /* Verify the proof. */
        return canRedeemUTXOHash(merkleLeafHash, proof);
    }
      
    /**
     * @dev Verify that a UTXO with the specified Merkle leaf hash can be redeemed
     * @param merkleLeafHash Merkle tree hash of the UTXO to be checked
     * @param proof Merkle tree proof
     * @return Whether or not the UTXO with the specified hash can be redeemed
     */
    function canRedeemUTXOHash(bytes32 merkleLeafHash, bytes32[] proof) public view returns (bool) {
        /* Check that the UTXO has not yet been redeemed and that it exists in the Merkle tree. */
        return((redeemedUTXOs[merkleLeafHash] == false) && verifyProof(proof, merkleLeafHash));
    }

    /**
     * @dev Redeem a UTXO, crediting a proportional amount of tokens (if valid) to the sending address
     * @param txid Transaction hash
     * @param outputIndex Output index of the UTXO
     * @param satoshis Amount of UTXO in satoshis
     * @param proof Merkle tree proof
     * @param pubKey Uncompressed ECDSA public key to which the UTXO was sent
     * @param isCompressed Whether the Bitcoin address was generated from a compressed public key
     * @param v v parameter of ECDSA signature
     * @param r r parameter of ECDSA signature
     * @param s s parameter of ECDSA signature
     * @return The number of tokens redeemed, if successful
     */
    function redeemUTXO (bytes32 txid, uint8 outputIndex, uint satoshis, bytes32[] proof, bytes pubKey, bool isCompressed, uint8 v, bytes32 r, bytes32 s) public returns (uint tokensRedeemed) {

        /* Calculate original Bitcoin-style address associated with the provided public key. */
        bytes20 originalAddress = pubKeyToBitcoinAddress(pubKey, isCompressed);

        /* Calculate the UTXO Merkle leaf hash. */
        bytes32 merkleLeafHash = keccak256(txid, originalAddress, outputIndex, satoshis);

        /* Verify that the UTXO can be redeemed. */
        require(canRedeemUTXOHash(merkleLeafHash, proof));

        /* Claimant must sign the Ethereum address to which they wish to remit the redeemed tokens. */
        require(ecdsaVerify(msg.sender, pubKey, v, r, s));

        /* Mark the UTXO as redeemed. */
        redeemedUTXOs[merkleLeafHash] = true;

        /* Calculate the redeemed tokens. */
        tokensRedeemed = SafeMath.mul(satoshis, multiplier);

        /* Track total redeemed tokens. */
        totalRedeemed = SafeMath.add(totalRedeemed, tokensRedeemed);

        /* Sanity check. */
        require(totalRedeemed <= maximumRedeemable);

        /* Credit the redeemer. */ 
        balances[msg.sender] = SafeMath.add(balances[msg.sender], tokensRedeemed);

        /* Mark the transfer event. */
        emit Transfer(address(0), msg.sender, tokensRedeemed);

        /* Mark the UTXO redemption event. */
        emit UTXORedeemed(txid, outputIndex, satoshis, proof, pubKey, v, r, s, msg.sender, tokensRedeemed);
        
        /* Return the number of tokens redeemed. */
        return tokensRedeemed;

    }

}

pragma solidity ^0.4.21;


/*
 * @title MerkleProof
 * @dev Merkle proof verification
 * @note Based on https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /*
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images is sorted.
   * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param _root Merkle root
   * @param _leaf Leaf of Merkle tree
   */
  function verifyProof(bytes32[] _proof, bytes32 _root, bytes32 _leaf) internal pure returns (bool) {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}

pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity ^0.4.21;


import "./ERC20Basic.sol";
import "../../math/SafeMath.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

pragma solidity ^0.4.21;

import "./BasicToken.sol";


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

pragma solidity ^0.4.21;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.21;

import "./BasicToken.sol";
import "./ERC20.sol";


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
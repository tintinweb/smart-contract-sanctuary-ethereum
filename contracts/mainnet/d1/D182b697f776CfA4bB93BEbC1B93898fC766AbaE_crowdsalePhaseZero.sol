// SPDX-License-Identifier: MIT
/**
 * @title obscurityDAO
 * @email [email protected]
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./founders.sol";


contract crowdsalePhaseZero is IERC20Upgradeable, FounderWallets, ReentrancyGuardUpgradeable { // ContextUpgradeable, 

    event DepositFunds(address indexed sender, uint amount, uint balance);
    
    IERC20Upgradeable private _token;

    address private _wallet;

    address payable _walletAddress;

    uint256 private _rate;
    uint256 private _ethAmountForSale;
    uint256 private _currentPhase;

    uint256 private initializedPhaseTwo;
    uint256 private initializedPhaseThree;
    uint256 private initializedPhaseFour;

    uint256 private _weiRaised;

    uint256 private phaseTwoETHAmount; // change before release depending on ETH price
    uint256 private phaseThreeETHAmount; // change before release depending on ETH price
    uint256 private phaseFourETHAmount; // change before release depending on ETH price

    uint256 _crowdSalePaused;
    uint256 private _crowdSalePhaseZeroInitialized; 
    mapping(address => bytes32[]) usedMessages;

    function initialize() initializer public {      
        require(_crowdSalePhaseZeroInitialized == 0);
        _crowdSalePhaseZeroInitialized = 1;
        _founders_init();
        __Context_init();
        __ReentrancyGuard_init();
        _ethAmountForSale = 200;
        setPhase(1);
        _rate = 5; //1;
        _walletAddress = payable(address(0x920Bf81087C296D57B4F7f5fCfd96cA71582F066)); // company wallet proxy address
        _wallet = address(0x920Bf81087C296D57B4F7f5fCfd96cA71582F066); // company wallet proxy address
        _token = IERC20Upgradeable(address(0x1d036Bbb3535a112186103a51A93B452307Ebd30)); // OBSC token proxy address
        
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(globals.ADMIN_ROLE, tx.origin);
        _grantRole(globals.UPGRADER_ROLE, tx.origin);

        _setupRole(globals.PAUSER_ROLE, address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0));
        _setupRole(globals.PAUSER_ROLE, address(0x6188b15bAE64416d779560D302546e5dE15E5d1E));

        phaseTwoETHAmount = 600;
        phaseThreeETHAmount = 4000;
        phaseFourETHAmount = 20000;
    }

    receive() external payable {
        emit DepositFunds(tx.origin, msg.value, _wallet.balance); 
        _forwardFunds();
    }

    function _forwardFunds() internal {
       (bool success, ) = _wallet.call{value:msg.value}("");
        require(success, "Transfer failed.");
    }

    function getPhaseZeroAddress() public view returns(address)
    {
        return address(this);
    }

    function getTokenAddress() public view returns(IERC20Upgradeable)
    {
        return _token;
    }

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    fallback() external payable  {
        buyTokens(_msgSender());
    }

    function token() public view returns (IERC20Upgradeable) {
        return _token;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function buyTokens(address beneficiary) public payable  nonReentrant() {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised + weiAmount;

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "0");
        require(weiAmount != 0, "1");
        require(_crowdSalePaused == 0);
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transferForCrowdSale(address(ADMIN_ADDRESS), beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * ((10**9) * _rate / _ethAmountForSale); // 10^7 * 5 5B 1 eth  200eth 2500/eth
        //return weiAmount * ((10**9) * _rate / 600); // 10^7 * 9 9B 1 eth  600eth 2500/eth
    }

    function pauseSale() 
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        _crowdSalePaused = 1;
    }

    function unpauseSale()
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        _crowdSalePaused = 0;
    }

    function setPhaseTwoRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 1);
        phaseTwoETHAmount = ethAmount;
    }

    function setPhaseThreeRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 2);
        phaseThreeETHAmount = ethAmount;
    }

    function setPhaseFourRate(uint256 ethAmount)
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(_currentPhase == 3);
         phaseFourETHAmount = ethAmount;
    }

    function initiatePhaseTwo()
    public {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseTwo != 1, "A.");
        require(_currentPhase == 1);
        initializedPhaseTwo = 1;
        pauseSale();
        setRate(9);
        setETHAmount(phaseTwoETHAmount);
        setPhase(2);
        unpauseSale();
    }

    function initiatePhaseThree()
    public  {
        require(hasRole(globals.PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseThree != 1);
        initializedPhaseThree = 1;
        require(_currentPhase == 2);
        pauseSale();
        setRate(36);
        setETHAmount(phaseThreeETHAmount);
        setPhase(3);
        unpauseSale();
    }

    function initiatePhaseFour()
    public  {
        require(hasRole(PAUSER_ROLE, msg.sender), "C");
        require(initializedPhaseFour != 1);
        require(_currentPhase == 3);
        initializedPhaseFour = 1;
        pauseSale();
        setRate(50);
        setETHAmount(phaseFourETHAmount);
        setPhase(4);
        unpauseSale();
    }

    function getPhaseTwoETHRate() public view returns (uint256) {
        return phaseTwoETHAmount; 
    }

    function getPhaseThreeETHRate() public view returns (uint256) {
        return phaseThreeETHAmount; 
    }

    function getPhaseFourETHRate() public view returns (uint256) {
        return phaseFourETHAmount; 
    }

    function getSalePhase() public view returns (uint256) {
        return _currentPhase; 
    }

    function getSaleRate() public view returns (uint256) {
        return _rate; 
    }

    function getSaleETHAmount() public view returns (uint256) {
        return _ethAmountForSale; 
    }

    function setPhase(uint256 newPhase) internal {
        _currentPhase = newPhase;
    }

    function setRate(uint256 newRate) internal {
        _rate = newRate;
    }

     function setETHAmount(uint256 newAmount) internal {
        _ethAmountForSale = newAmount;
    }

    /*overrides*/
    function allowance(address owner, address spender) external override view returns (uint256) {
        _token.allowance(owner, spender);
    } 

    function approve(address spender, uint256 amount) external override returns (bool) {
        return _token.approve(spender, amount);
    }

    function totalSupply() external override view returns (uint256) {
        return _token.totalSupply();
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _token.balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _token.transfer(recipient, amount);
    }

    function transferForCrowdSale(
        address sender,
        address recipient,
        uint256 amount
    ) external override {
        _token.transferForCrowdSale(sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _token.transferFrom(sender, recipient, amount);
    }

    /*Founder functions - ETH Amount*/ 
    function completeETHAmountChangeProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        if(founderExecution(proposalID) == 1)
        {
            setETHAmount(proposalVotes[proposalID].newAmount);
        }
    }
    
    function createETHAmountChangeProposal(uint256 newAmount, bytes32 desc) 
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE)  {
        _createETHAmountProposal(newAmount, desc);
    }

    function getPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPState(proposalID);
    }

    function getPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPDesc(proposalID);
    }

    function founderETHAmountChangeVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true, "O");
            f1VoteOnETHAmountChangeProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true, "T");
            f2VoteOnETHAmountChangeProposal(vote, proposalID);
        }
    }
    

    /*Founder Functions - Addr*/
    function completeAddrTransferProposal(uint256 proposalID)
    public 
    virtual onlyRole(PAUSER_ROLE) {
        addressSwapExecution(proposalID);
    }
    
    function createAddrTransferProposal(address payable oldAddr, address payable newAddr, bytes32 desc)  
    public 
    virtual
    nonReentrant() 
    onlyRole(PAUSER_ROLE) {
        _createAddressSwapProposal(oldAddr, newAddr, desc);
    }

    function getAddrPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        return gPSwapState(proposalID);
    }

    function getAddrPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        return gPSwapDesc(proposalID);
    }

    function founderAddrVote(
        uint256  proposalID,
        uint256 vote,
        address to, 
        uint256 amount, 
        string memory message,
        uint nonce,
        bytes memory signature
    ) external 
    nonReentrant()
    onlyRole(PAUSER_ROLE) {
        if (tx.origin == founderOne.founderAddress) {
            require(verify(founderOne.founderAddress, to, amount, message, nonce, signature) == true);
            f1VoteOnSwapProposal(vote, proposalID);
        }
        if (tx.origin == founderTwo.founderAddress) {
            require(verify(founderTwo.founderAddress, to, amount, message, nonce, signature) == true);
            f2VoteOnSwapProposal(vote, proposalID);
        }
    }

    /*Signature Methods*/
    function getMessageHash(
       address _to,
       uint _amount,
       string memory _message,
       uint _nonce
    ) 
    public 
    pure returns (bytes32) {
        return keccak256(abi.encode(_to, _amount, _message, _nonce));
    }

    function verify(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) 
    public returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);

        for(uint i = 0; i < usedMessages[tx.origin].length; i++) {
            require(usedMessages[tx.origin][i] != messageHash);
        }
        bool temp = recoverSigner(messageHash, signature) == _signer;
        if (temp)
            usedMessages[tx.origin].push(messageHash);
        return temp;
    }

    function recoverSigner(bytes32 msgHash, bytes memory _signature)
    public
    pure returns (address) {
        bytes32 _temp = ECDSAUpgradeable.toEthSignedMessageHash(msgHash);
        address tempAddr = ECDSAUpgradeable.recover(_temp, _signature);
        return tempAddr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferForCrowdSale(
        address sender,
        address recipient,
        uint256 amount
    ) external;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * @title obscurityDAO
 * @email [email protected]
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "./globals.sol";

abstract contract FounderWallets is globals {

    enum fps {
        Active,
        Defeated,
        Succeeded,
        ExecutedByFounders,
        Queued
    }

    struct FounderWallet {
        string founderAlias;
        address payable founderAddress;
    }

    struct FounderETHAmountProposal {
        uint256 f1Vote;
        uint256 f2Vote;

        bytes32 pDesc;
        fps pState;
        uint256 newAmount;
        bool exists;
    }

    struct AddressSwapProposal {
        uint256 f1Vote;
        uint256 f2Vote;

        bytes32 pDesc;
        fps sState;
        address payable swapOld;
        address payable swapNew;
        bool exists;
        uint256 createdTime;
    }

    event ETHAmountProposalCreated(address indexed _from, uint256 _id, string _value);
    event SwapAddressProposalCreated(address indexed _from, uint256 _id, string _value);
    
    mapping(uint256 => FounderETHAmountProposal) proposalVotes;
    mapping(uint256 => AddressSwapProposal) addressSwapProposalVotes;

    FounderWallet founderOne;
    FounderWallet founderTwo;

    uint256 lastPID;
    uint256 lastSwapPID;

    function _founders_init() 
    internal 
    onlyInitializing {
        globals_init();
        addFounderOne(
            "FO",           
            payable(address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0))
           // "FounderOne"
        );
        addFounderTwo(
            "FT",
            payable(address(0x6188b15bAE64416d779560D302546e5dE15E5d1E))
           // "FounderTwo"
        );
        lastPID = 0;
        lastSwapPID = 0;
    }

    function _createAddressSwapProposal(address payable oldAddr, address payable newAddr, bytes32 desc) 
    internal 
    virtual {
        require(oldAddr == founderOne.founderAddress        || 
                oldAddr == founderTwo.founderAddress        || 
                oldAddr == globals.ADMIN_ADDRESS
        );

        if(!addressSwapProposalVotes[lastSwapPID + 1].exists) {
        } 
        else require(1 == 0);
        addressSwapProposalVotes[++lastSwapPID] = AddressSwapProposal( 0, 0, 
            desc, fps.Queued, oldAddr, newAddr, true, block.timestamp);
        emit SwapAddressProposalCreated(msg.sender, lastSwapPID, "C");
    }

    function _createETHAmountProposal(uint256 newAmount, bytes32 desc) 
    internal 
    virtual  {

        if(!proposalVotes[lastPID + 1].exists) {
        } 
        else require(1 == 0);
        proposalVotes[++lastPID] = FounderETHAmountProposal(0, 0,
         desc, fps.Queued, newAmount, true);
        emit ETHAmountProposalCreated(msg.sender, lastPID, "C");
    }

    function sFOneAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        founderOne.founderAddress = _newAddress;
    }

    function sFTwoAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        founderOne.founderAddress = _newAddress;
    }

    function addFounderOne(
        string memory _fAlias,
        address payable _fAddress)
    private {
        if (
            (keccak256(bytes(founderOne.founderAlias))) != keccak256(bytes("O"))
        ) {
            founderOne = FounderWallet(_fAlias, _fAddress);
        }
    }

    function addFounderTwo(
        string memory _fAlias,
        address payable _fAddress)
    private {
        if (
            (keccak256(bytes(founderTwo.founderAlias))) != keccak256(bytes("T"))
        ) {
            founderTwo = FounderWallet(_fAlias, _fAddress);
        }
    }
    /*Functions on proposals to change address*/
    function f1VoteOnSwapProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {

        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated) {
            require(1 == 0);
        }
        if(p.sState == fps.Queued)
            addressSwapProposalVotes[proposalID].sState = fps.Active;
        
        if(vote != 1) {
            addressSwapProposalVotes[proposalID].f1Vote = vote;
            addressSwapProposalVotes[proposalID].sState = fps.Defeated;
            require(1 == 0); 
        }

        if(vote == 1) {
            addressSwapProposalVotes[proposalID].f1Vote = vote;
        }
    }

    function f2VoteOnSwapProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {

        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated) {
            require(1 == 0);
        }
        if(p.sState == fps.Queued)
            addressSwapProposalVotes[proposalID].sState = fps.Active;
        
        if(vote != 1)
        {
            addressSwapProposalVotes[proposalID].f2Vote = vote;
            addressSwapProposalVotes[proposalID].sState = fps.Defeated;
            require(1 == 0);
        }

        if(vote == 1)
        {
            addressSwapProposalVotes[proposalID].f2Vote = vote;
        }
    }

    function addressSwapExecution(uint256 proposalID) 
    internal
    virtual {
        addrSwapFinalState(proposalID);
        
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        if (p.sState != fps.Succeeded)
            require(1 == 0, "0");

        if (founderOne.founderAddress == p.swapOld) {
            founderOne.founderAddress = p.swapNew;
            _revokeRole(globals.PAUSER_ROLE, p.swapOld);
            _grantRole(globals.PAUSER_ROLE, p.swapNew);
        }
        else if(founderTwo.founderAddress == p.swapOld) {
            founderTwo.founderAddress = p.swapNew;
            _revokeRole(globals.PAUSER_ROLE, p.swapOld);
            _grantRole(globals.PAUSER_ROLE, p.swapNew);
        }
        else if(globals.ADMIN_ADDRESS == p.swapOld)
        {
            _grantRole(globals.UPGRADER_ROLE, p.swapNew);
            _grantRole(globals.ADMIN_ROLE, p.swapNew);
            _grantRole(DEFAULT_ADMIN_ROLE, p.swapNew);
            globals.ADMIN_ADDRESS == p.swapNew;
            _revokeRole(globals.UPGRADER_ROLE, globals.ADMIN_ADDRESS);
            _revokeRole(globals.ADMIN_ROLE, globals.ADMIN_ADDRESS);
            _revokeRole(DEFAULT_ADMIN_ROLE, globals.ADMIN_ADDRESS);           
        }
        
        addressSwapProposalVotes[proposalID].sState = fps.ExecutedByFounders;
    }

    function addrSwapFinalState(uint256 proposalID) 
    private {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated)
        {
            require(1 == 0, "1");
        }

        if (block.timestamp < p.createdTime + 30 days) {
            require(p.f1Vote + p.f2Vote == 2, "N");
            {
                addressSwapProposalVotes[proposalID].sState = fps.Succeeded;
            }
        }
        else {
            addressSwapProposalVotes[proposalID].sState = fps.Succeeded;
        }
    }

    function gPSwapState(uint256 proposalID) 
    public 
    view 
    returns (uint256) {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        if (p.sState == fps.Active)
            return 1;
        else if (p.sState == fps.Defeated)
            return 4;
        else if (p.sState == fps.Succeeded)
            return 2;
        else if (p.sState == fps.ExecutedByFounders)
            return 3;
        else 
            return 0;
    }

    function gPSwapDesc(uint256 proposalID) 
    public 
    view 
    returns (bytes32) {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        return p.pDesc;
    }

    /*Functions on proposals to change amount for current phase*/
    function f1VoteOnETHAmountChangeProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated)
        {
             require(1 == 0, "C");
        }
        if(p.pState == fps.Queued)
            p.pState = fps.Active;
        
        if(vote != 1)
        {
            p.f1Vote = vote;
            p.pState = fps.Defeated;
        }

        if(vote == 1)
        {
            p.f1Vote = vote;
        }
        proposalVotes[proposalID] = p;
    }

    function f2VoteOnETHAmountChangeProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated)
        {
            require(1 == 0);
        }
        if(p.pState == fps.Queued)
            proposalVotes[proposalID].pState = fps.Active;
        
        if(vote != 1)
        {
            proposalVotes[proposalID].f2Vote = vote;
            proposalVotes[proposalID].pState = fps.Defeated;
        }

        if(vote == 1)
        {
            proposalVotes[proposalID].f2Vote = vote;
        }
    }

    function founderExecution(uint256 proposalID) 
    internal
    virtual returns (uint256) {
        sFinalState(proposalID);
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        if (p.pState != fps.Succeeded)
            require(1 == 0, "!");
        
        proposalVotes[proposalID].pState = fps.ExecutedByFounders;
        return 1;
    }

    function sFinalState(uint256 proposalID) 
    private {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated) {
            require(0 == 1);
        }
        else{
            require(p.f1Vote + p.f2Vote == 2, "N");
            proposalVotes[proposalID].pState = fps.Succeeded;
        }
    }

    function gPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        if (p.pState == fps.Active)
            return 1;
        else if (p.pState == fps.Defeated)
            return 4;
        else if (p.pState == fps.Succeeded)
            return 2;
        else if(p.pState == fps.ExecutedByFounders)
            return 3;
        else 
            return 0;
    }

    function gPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        return p.pDesc;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * @title obscurityDAO
 * @email [email protected]
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
abstract contract globals is AccessControlUpgradeable{

    address payable ADMIN_ADDRESS;
    bytes32 PAUSER_ROLE; // can pause the network
    bytes32 UPGRADER_ROLE; // see admin
    bytes32 ADMIN_ROLE; // COMPANY WALLET ROLE USED AS ADDITIONAL LAYER OFF PROTECTION initiats upgrades, founder wallet changes
    bytes32 FOUNDER_ROLE; // USED AS ADDITIONAL LAYER OFF PROTECTION (WE CANT LOSE ACCESS TO THESE WALLETS) approves new charites
   
    function globals_init() internal onlyInitializing{
        __AccessControl_init();
                              
        ADMIN_ADDRESS = payable(address(0x00d807590d776bA30Db945C775aeED85ABFa7020));
        PAUSER_ROLE = keccak256("P_R"); // can pause the network
        UPGRADER_ROLE = keccak256("U_R"); // see admin
        FOUNDER_ROLE = keccak256("F_R"); // USED AS ADDITIONAL LAYER OFF PROTECTION (WE CANT LOSE ACCESS TO THESE WALLETS) approves new charites    
    }

    //UNITS
    modifier contains (string memory what, string memory where) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        uint256 found = 0;

        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = 1;
                break;
            }
        }
    require (found == 1);
    _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
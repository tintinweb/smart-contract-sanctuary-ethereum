// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

// NOTHING IN THIS COMMENT IS FINANCIAL ADVISE
// DO YOUR OWN RESEARCH TO VERIFY ANY STATEMENTS OR CLAIMS
// READ THE CONTRACT (WHICH HAS NOT BEEN AUDITED) BEFORE INTERACTING

/*
██████╗ ██╗██╗     ██╗     ██╗ ██████╗ ███╗   ██╗
██╔══██╗██║██║     ██║     ██║██╔═══██╗████╗  ██║
██████╔╝██║██║     ██║     ██║██║   ██║██╔██╗ ██║
██╔══██╗██║██║     ██║     ██║██║   ██║██║╚██╗██║
██████╔╝██║███████╗███████╗██║╚██████╔╝██║ ╚████║
╚═════╝ ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝
                                                 
██████╗  ██████╗ ██╗     ██╗      █████╗ ██████╗ 
██╔══██╗██╔═══██╗██║     ██║     ██╔══██╗██╔══██╗
██║  ██║██║   ██║██║     ██║     ███████║██████╔╝
██║  ██║██║   ██║██║     ██║     ██╔══██║██╔══██╗
██████╔╝╚██████╔╝███████╗███████╗██║  ██║██║  ██║
╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
                                                 
██████╗ ██████╗  ██████╗ ██████╗                 
██╔══██╗██╔══██╗██╔═══██╗██╔══██╗                
██║  ██║██████╔╝██║   ██║██████╔╝                
██║  ██║██╔══██╗██║   ██║██╔═══╝                 
██████╔╝██║  ██║╚██████╔╝██║                     
╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝                     

¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢£££¢¢¢¢£££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢£ƒ1₹₹₮₮₮£££¢£££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢¢¢¢£₮1₹;:,,,,,,,;;1ƒ¢¢¢££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢¢¢¢₮:,.........,,::;1₮£¢£££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢¢₮;:,.....,:::;;;;;₹₮1ƒ¢¢££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢£₹:...,,,:;;;;;;;;;₹11ƒƒ£££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢₲₮,,.,,,,:;;;::;;;₹1₹:::;₮£¢££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢£;..,,,,,,:;:;1₹₹:;₹;;₹1;₮¢££££££££££££££££££££££££££¢¢¢$$$$$$££££££££££££££££££££££££££££££
¢¢¢¢¢¢¢¢¢₮;,,,,.,,::;₹;;;:;;₹₹₹111£¢££££££££££££££££££££££¢¢$$¢¢¢¢¢$$¢££££££££££££££££££££££££££££££
₲₲₲¢¢¢₲¢₲¢1,.,..,::;;;₹₹111₹₹;;:;₹₹ƒ¢££££££££££££££££££££¢¢$$$¢£ƒƒ£¢¢££££££££££££££££££££££££££¢¢¢¢¢
₲₲₲₲₲¢¢¢¢¢ƒ;,...,,:::;₹₹1₮₮₮1₹;₹₹₮1₹£¢££££££££££££££££££¢¢$$$$ƒ₮₮ƒ£¢££££££££££££££¢£££££££££££¢¢¢¢¢¢
₲¢¢¢¢¢¢¢¢¢¢¢ƒ₹,,:;:::;₹₹₹1111₹;:,,₹1ƒ¢£££££££££££££££££££¢$$¢ƒ₮₮ƒ¢¢£££££££££££££¢¢££££££££¢¢¢¢¢¢¢¢¢¢
¢¢¢¢¢¢¢¢¢¢¢¢₲₲1₹1₹₹::;;₹₹₹₹11₹;₹1₹;₮££££££££££££££££££ƒ₮£¢$$¢ƒ₮₮££££££££££££££¢¢¢££¢¢£¢£££¢¢¢¢¢¢¢¢¢¢
¢¢¢¢¢¢¢¢¢¢¢¢¢¢£1;₹₹;::;;₹₹₹₹₹₹₹₹11;;1££££££££££££££££₮1₮£₲0₲£₮₮£¢££££££₮₮¢¢¢¢¢¢£ƒƒ£ƒ₮£¢£¢¢£¢£¢¢¢¢¢£¢
¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢¢£₹,:::::::;:;₹₹₹;;;:;£¢££££££££££££₮₮₮₹1¢00₲¢ƒƒ£¢££¢₮11;:;1;₹₮₹₹₹₹₹₹1£££¢¢£¢₲₲₲¢££¢¢
¢¢¢¢¢¢¢¢¢¢¢¢₲₲₲₲ƒ,,,:::;;;:,,,:;;;:::₹₮ƒ£¢£££££££₮₹1₮1:₮¢₲0800¢¢£ƒ₮₮1;::::,:::;1₮₮₮₮ƒ£¢££¢¢0$$$$$¢¢¢
¢¢¢¢¢¢¢¢₲₲¢£ƒ₮1₹,,,,..,,:;;;,.......,,.:;₮££¢¢£ƒ1₹1ƒ₮;:ƒ₲₲0000₲¢₮1::::;::;:,,₹¢£££££££££¢₲$$$$$$$$$0
¢¢¢¢¢¢₲¢ƒ₹:,...;:.........,:::,.,.....::.,,ƒƒ;₮₹₹₮ƒ₮₹:::1ƒ££¢0₲££₮1;,,;:,:,:₮£££££££££¢¢$$$$$$$$$$$$
¢¢¢¢₲£1:,......,::,......,..,,...,,....,,,:₮;;₹1₮ƒ₮₹:;:₹££££08₲¢₲¢¢ƒ₮;:,,,;£¢£££££££¢¢₲$$$$$$$$$$$$$
¢¢¢¢1.,:.,.......,.......,.:₹,...,,...:,,;1111₮₮₮1;:;:₹ƒ£££¢8$¢¢₲¢₲₲¢;,::;ƒ££££££££¢$$$$$$$$$$$$$$$¢
¢¢¢₮..,,....;:.,..........,,..,,..,,,,;₹₮₮₮₮₮111₹;:::₮£££££08$$$£ƒ₲₲¢1₮ƒ£££££££££¢$$$$$$$$$$$$$$$$¢£
¢¢¢1.,..:::;:......,..........,,,..... ;ƒ₮₮₮1₹:::.:;1££££₮¢$$$$$$£¢¢¢£££££££££££¢₲$$$$$$$$$$$$$$$¢££
¢¢¢₮.,.,;:,,.......,......,,,.....;;₹:₹11₮1₹:,..,.,ƒ₮₮ƒ£ƒ₮0$$$$$$$$¢;₹££££££££££££₲$$$$$$$$$$$$¢££££
¢£¢1......,,,.,;,,,,....,... ..,;₮₲¢£¢1;:;:;₹;:,....:::₹£$$$$$$$$$$£..1£ƒ££££££££ƒƒ£¢₲$$$$$$$₲¢£££££
£¢ƒ,,....,,...,,.........,1ƒ₹₹₮1;:,:,. ..,,:;;;,..,,:..1$$$$$$$$$$$₹..₹£ƒƒƒ£££ƒƒƒ££ƒƒƒ££¢₲$$₲₲££££££
£¢₹............,:₹££:,,;1ƒ₲£₮1:.......,,,,.......::,..₹$$$$$$$$$$$$,,.1£ƒƒƒƒƒƒƒƒƒƒƒƒƒ££ƒƒƒƒ£££££££££
£ƒ,...........:ƒ1¢81,;11:... ........,,,.............$$$$$$$$$$$$$$..:ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ£££££££££££
£ƒ,::..:₮:..:;,₹₮,;:;:.  ..........,,........,,.....:$$$$$$$$$$$$$...₹ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ££££££
££;....₮;,..,,.;:.,,. ............,..........,,.....;$$$$$$$$$$$$:..,1ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ££££
ƒ£1 ..,,..................,,.................  .....:$$$$$$$$$$$$.,.,1ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
££ƒ;,.,....................................  ...........,:$$$$$$:,,.:₮ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
ƒƒ£ƒ:,.............,.........................................,::,,,.;ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
£ƒƒƒ;,,.............,......  .....,,.  . .. ....................,,.,₮ƒƒƒƒƒ₮ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
££££₮,,,,,............... .;,.....:;;::₹₹£₮:.          ..........,,₹ƒ₮₮₮₮₮ƒƒ₮ƒƒƒƒƒ₮ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
£££££1:;;₹::₹:::::;;::;₹;:₹1₹::₹ƒƒ1ƒ£££ƒ££¢¢ƒ₮₹₹:;:,₹₹,,,,:,,..,:,;₮ƒƒƒƒƒƒƒƒƒƒƒƒ₮₮₮₮₮₮ƒƒƒƒƒƒƒƒƒƒ₮₮₮₮
£££££ƒ;:::::;:;;;₹₹₹₹₹1₹₹;₹₹11ƒ£₲₲₲£ƒƒƒƒƒ₮₮₮ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ111ƒƒƒƒƒƒ£ƒƒƒƒ₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮₮*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

import "./ECDSA.sol";

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

/// @author Gutenblock.eth
/// @title BillionDollarDrop
contract BillionDollarDrop is Ownable, ReentrancyGuard {
    using Address for address payable;
    using ECDSA for bytes32;

    /// @dev Mapping of authorized signer addresses.
    mapping(address => bool) public authorizedSigner;
    /// @dev Keeping track of used message signatures.
    mapping(bytes32 => bool) public signedMessageHashUsed;
    /// @dev Ability to invalidate all signatures with a given nonce.
    mapping(uint256 => bool) public nonceInvalid;
    /// @dev Mapping of token contract addresses to recipient addresses and amounts claimed.
    mapping(address => mapping(address => uint256)) public tokensClaimed;

    /// @dev EVENTS
    /* ╔═╗┬  ┬┌─┐┌┐┌┌┬┐┌─┐
       ║╣ └┐┌┘├┤ │││ │ └─┐
       ╚═╝ └┘ └─┘┘└┘ ┴ └─┘ */
    event PaymentReceived(address indexed from, uint256 amount);

    event AuthorizedSignerSet(address indexed signer, bool authorized);
    event NonceInvalidSet(uint256 indexed nonce, bool invalid);

    event RecipientClaimedErc20(address indexed recipient, address indexed token, uint256 amount, uint256 nonce);
    
    event PaymentReleased(address indexed to, uint256 amount);
    event PaymentReleasedErc20(address indexed token, address indexed to, uint256 amount);

    /// @dev CONSTRUCTOR
    /* ╔═╗┌─┐┌┐┌┌─┐┌┬┐┬─┐┬ ┬┌─┐┌┬┐┌─┐┬─┐
       ║  │ ││││└─┐ │ ├┬┘│ ││   │ │ │├┬┘
       ╚═╝└─┘┘└┘└─┘ ┴ ┴└─└─┘└─┘ ┴ └─┘┴└─ */
    constructor() {
        authorizedSigner[msg.sender] = true;
        emit AuthorizedSignerSet(msg.sender, true);
    }

    /// @dev ECDSA AIRDROP FUNCTIONS
    /* ╔═╗╔═╗╔╦╗╔═╗╔═╗  ╔═╗┬ ┬┌┐┌┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
       ║╣ ║   ║║╚═╗╠═╣  ╠╣ │ │││││   │ ││ ││││└─┐
       ╚═╝╚═╝═╩╝╚═╝╩ ╩  ╚  └─┘┘└┘└─┘ ┴ ┴└─┘┘└┘└─┘ */
    /* ==================================================================
       Signature Verification Overview 

        # Signing
            1. Create message to sign
            2. Hash the message
            3. Sign the hash (off chain, keep your private key secret)

        # Verify
            1. Recreate hash from the original message
            2. Recover signer from signature and hash
            3. Compare recovered signer to claimed signer
            4. Perform the gated operation
    ================================================================== */
    
    /** @dev Creates a message hash from input data.
      * @dev Force payout of any curator that was previously set
      * @dev so that funds paid with a curator set are paid out as promised.
      * @param _domain A unique string for the drop. Protects against a generic signature.
      * @param _to The address of the recipient / claimer.
      * @param _token The address of the token to claim.
      * @param _amount The amount of the token to claim (in wei).
      * @param _nonce A nonce (that can be invalidated).
      */
    function getMessageHash(
        string calldata _domain,
        address _to,
        address _token,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_domain, _to, _token, _amount, _nonce));
    }

    /** @dev Calls ECDSA toEthSignedMessageHash() function.
      * @dev This appends "Ethereum Signed Message: " to the hash, and
      * @dev then returns the hash of that new string.
      * @param _hash a hashed message.
      */
    function getEthSignedMessageHash(bytes32 _hash) public pure returns (bytes32) {
        return _hash.toEthSignedMessageHash();
    }

    /** @dev Calls ECDSA recover() function.
      * @dev This returns the signer address of the message
      * @dev given the signature and the hash.
      * @param _hash a hashed message.
      * @param _signature a signature for the hashed message.
      */
    function recoverSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        return _hash.recover(_signature);
    }

    /** @dev Sets an allowed signer address in the contract.
      * @param _signer an address that is (not) allowed to create valid signatures.
      * @param _authorized a bool indicating whether the _signer is allowed to create valid signatures.
      */
    function setAuthorizedSigner(address _signer, bool _authorized) public onlyOwner {
        authorizedSigner[_signer] = _authorized;
        emit AuthorizedSignerSet(_signer, _authorized);
    }

    /** @dev Sets whether a nonce is invalid.
      * @param _nonce a number that allows one or many signatures to be invalidated.
      * @param _invalid a bool indicating whether the _nonce is invalid.
      */
    function setNonceInvalid(uint256 _nonce, bool _invalid) public onlyOwner {
        nonceInvalid[_nonce] = _invalid;
        emit NonceInvalidSet(_nonce, _invalid);
    }

    /** @dev Verifies a message against a signature.
      * @dev Performs the gated operation if the message is valid.
      * @param _domain A unique string for the drop. Protects against a generic signature.
      * @param _token The address of the token to claim.
      * @param _amount The amount of the token to claim (in wei).
      * @param _nonce A nonce (that can be invalidated).
      * @param _signature A signature for the message from an authorized signer.  
      */
    function verifyAndClaimErc20(
        string calldata _domain,
        address _token,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public virtual nonReentrant() {
        // checks
        // -- 1. Check the signature to ensure it is authorized.
        require(msg.sender == tx.origin, "Auth: Only the recipient EOA can claim.");
        bytes32 _messageHash = getMessageHash(_domain, msg.sender, _token, _amount, _nonce);
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
        address _recoveredSigner = recoverSigner(_ethSignedMessageHash, _signature);
        bool    _isAuthorizedSigner = authorizedSigner[_recoveredSigner];
        require(_isAuthorizedSigner, "Auth: Signature not valid, or not by an authorized signer.");

        // -- 2. Check to make sure that the nonce has not been invalidated.
        require(nonceInvalid[_nonce] != true, "Auth: Nonce has been invalidated.");

        // -- 3. Check to make sure the message hasnt been used yet.
        require(signedMessageHashUsed[_ethSignedMessageHash] == false, "Auth: Signed message has already been used.");

        // effects
        // -- 4. If everything is valid, update state.
        signedMessageHashUsed[_ethSignedMessageHash] = true;
        tokensClaimed[_token][msg.sender] += _amount;

        // interactions
        // -- 5. Then, send the token as specified.
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount);
        emit RecipientClaimedErc20(msg.sender, _token, _amount, _nonce);
    }

    /// @dev CONTRACT OWNER FINANCIAL FUNCTIONS
    /* ╔═╗┬┌┐┌┌─┐┌┐┌┌─┐┬┌─┐┬    ╔═╗┬ ┬┌┐┌┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
       ╠╣ ││││├─┤││││  │├─┤│    ╠╣ │ │││││   │ ││ ││││└─┐
       ╚  ┴┘└┘┴ ┴┘└┘└─┘┴┴ ┴┴─┘  ╚  └─┘┘└┘└─┘ ┴ ┴└─┘┘└┘└─┘ */
    /// @dev Allow the contract to receive payments.
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @dev Triggers payout of all ETH held by contract. 
    function withdraw() external nonReentrant() onlyOwner() {
        uint256 _startingBalance = address(this).balance;
        payable(this.owner()).sendValue(_startingBalance);
        emit PaymentReleased(this.owner(), _startingBalance);
    }

    /** @dev Triggers payout of all ERC20 held by contract.
      * @param _token The address of the token to claim.
      * @param _amount The amount of the token to claim (in wei).
      */
    function withdrawErc20(address _token, uint256 _amount) public virtual nonReentrant() onlyOwner() {
        SafeERC20.safeTransfer(IERC20(_token), this.owner(), _amount);
        emit PaymentReleasedErc20(_token, this.owner(), _amount);
    }
}
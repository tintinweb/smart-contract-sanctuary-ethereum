/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /// @notice increase total supply of token
    function mint(address account, uint256 amount) external;
    /// @notice who can increase total supply
    function addMinter(address account) external;
    /// @notice remove msg.sender address from minter role
    function renounceMinter() external;
    /// @return true if account has minter role
    function isMinter(address account) external view returns (bool);
}

/// @title contains all modifiers and stores variables.
contract MultiSigModifiers {
    address public TokenAddress; //will change only in constractor
    uint256 public MinSigners; //min signers amount to do action - will change only in constractor
    uint256 public sigCounter; //vote count if the transaction can be implemented
    mapping(address => bool) public AuthorizedMap; //can self change
    mapping(uint => address) public VotesMap; // who voted
    uint256 public Amount; //hold temp data for transaction
    address public TargetAddress; //hold temp data for transaction

    modifier OnlyAuthorized() {
        require(
            AuthorizedMap[msg.sender],
            "User is not Authorized"
        );
        _;
    }

    modifier isThisContractMinter() {
        require(
            IERC20(TokenAddress).isMinter(address(this)),
            "MultiSig doesn't have a minter role"
        );
        _;
    }

    modifier ValuesCheck(address target, uint256 amount) {
        require(
            TargetAddress == target && Amount == amount,
            "Must use the same values from initiation"
        );
        _;
    }

    modifier NotVoted(){
        for (uint256 i = 0; i < sigCounter; i++) {
            require(VotesMap[i] != msg.sender, "your vote is already accepted");
        }
        _;
    }
}


/// @title contains all events.
contract MultiSigEvents {
    event Setup(address[] Authorized, address Token, uint256 MinSignersAmount);
    event StartMint(address target, uint256 amount);
    event CompleteMint(address target, uint256 amount);
    event StartChangeOwner(address target);
    event CompleteChangeOwner(address target);
    event AuthorizedChanged(address newAuthorize, address OldAuthorize);
    event NewSig(address Signer, uint256 CurrentSigns, uint256 NeededSigns);
    event Clear();
}
/// @title contains all request initiations.
contract MultiSigInitiator is MultiSigModifiers, MultiSigEvents {
    /// @dev initiate a request to mint tokens
    function InitiateMint(address target, uint256 amount)
        external
        OnlyAuthorized
        isThisContractMinter
        ValuesCheck(address(0), 0)
    {
        require(
            amount > 0 && target != address(0),
            "Target address must be non-zero and amount must be greater than 0"
        );
        Amount = amount;
        TargetAddress = target;
        emit StartMint(target, amount);
        _confirmMint(target, amount);
    }

    /// @dev initiate a change of ownership of minting tokens
    function InitiateTransferOwnership(address target)
        external
        OnlyAuthorized
        isThisContractMinter
        ValuesCheck(address(0), 0)
    {
        require(target != address(0), "Target address must be non-zero");
        TargetAddress = target;
        emit StartChangeOwner(target);
        _confirmTransferOwnership(target);
    }

    /// @return true if there are enough votes to complete the transaction
    function IsFinalSig() internal view returns (bool) {
        return sigCounter == MinSigners;
    }

    function _newSignature() internal NotVoted {
        VotesMap[sigCounter++] = msg.sender;
        emit NewSig(msg.sender, sigCounter, MinSigners);
    }

    function _mint(address target, uint256 amount) internal {
        IERC20(TokenAddress).mint(target, amount);
        emit CompleteMint(target, amount);
    }

    /// @dev cancel the minting request
    function ClearConfirmation() public OnlyAuthorized {
        Amount = 0;
        TargetAddress = address(0);
        sigCounter = 0;
        emit Clear();
    }

    function _confirmMint(address target, uint256 amount) internal {
        _newSignature();
        if (IsFinalSig()) {
            _mint(target, amount);
            ClearConfirmation();
        }
    }

    function _confirmTransferOwnership(address target) internal {
        _newSignature();
        if (IsFinalSig()) {
            IERC20(TokenAddress).addMinter(target);
            IERC20(TokenAddress).renounceMinter();
            emit CompleteChangeOwner(target);
            ClearConfirmation();
        }
    }
}


/// @title contains confirmation requests.
contract MultiSigConfirmer is MultiSigInitiator {
    /// @dev only authorized address can change himself
    function ChangeAuthorizedAddress(address authorize)
        external
        OnlyAuthorized
    {
        require(
            !AuthorizedMap[authorize],
            "AuthorizedMap must have unique addresses"
        );
        require(authorize != address(0), "Authorize address must be non-zero");
        emit AuthorizedChanged(authorize, msg.sender);
        AuthorizedMap[msg.sender] = false;
        AuthorizedMap[authorize] = true;
    }

    /// @dev collects votes to confirm mint tokens
    /// if there are enough votes, coins will be minted
    function ConfirmMint(address target, uint256 amount)
        external
        OnlyAuthorized
        ValuesCheck(target, amount)
    {
        _confirmMint(target, amount);
    }

    /// @dev transfers the right to mint tokens
    function ConfirmTransferOwnership(address target)
        external
        OnlyAuthorized
        ValuesCheck(target, 0)
    {
        _confirmTransferOwnership(target);
    }
}

/// @author The-Poolz contract team
/// @title Smart contract of using multi signature for approval sending transactions.
contract MultiSig is MultiSigConfirmer {
    /// @param Authorized who can votes and initiate mint transaction
    /// @param Token mintable token address
    /// @param MinSignersAmount minimum amount of votes for a successful mint transaction
    constructor(
        address[] memory Authorized,
        address Token,
        uint256 MinSignersAmount
    ) {
        require(Authorized.length >= MinSignersAmount, "Authorized array length must be equal or greater than MinSignersAmount");
        require(Token != address(0), "Token address must be non-zero");
        require(MinSignersAmount > 1, "Minimum signers must be greater than 1");
        for (uint256 index = 0; index < Authorized.length; index++) {
            require(Authorized[index] != address(0), "Invalid Authorized address");
            AuthorizedMap[Authorized[index]] = true;
        }
        TokenAddress = Token;
        MinSigners = MinSignersAmount;
        emit Setup(Authorized, Token, MinSignersAmount);
    }
}
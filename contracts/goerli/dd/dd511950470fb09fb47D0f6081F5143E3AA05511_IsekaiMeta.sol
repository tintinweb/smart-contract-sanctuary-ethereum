// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ECDSA.sol";
import "./IIsekaiMeta.sol";

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdlc:;,''........'',;:loxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxo:,..                           ..,cokKWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWKkdc,.        ...,;:cclloooooollcc:;'..       .,cd0NWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWNNXXNN0xc,.       .':coxk0KKXXXXXXXXXXXXXXXXXXK0Oxoc;..      ':d0WMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMNOoc;'...'..     ..;cdk0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOdl;.     .,lk0XWMMMMMMMMMMMMM
MMMMMMMMW0l'               ;kKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0o.       ..,:d0WMMMMMMMMM
MMMMMMMNo.    ...'''...    .c0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKd'             .;xXMMMMMMM
MMMMMMX:    .,;::::::::,.    :0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKl.   ..,,,,'..     ,kWMMMMM
MMMMMNc    .;:::::::::::;.    ';;;:ldOKXXXXXXXXXXXXXXXXXXXXXXXX0xoc:;,;:,    .;::::::::;'.   .xWMMMM
MMMMWx.   .:::::::::::,..            .,lOXXXXXXXXXXXXXXXXXXXKx:.             .;::::::::::;.   .kMMMM
MMMMX;   .;::::::::::;.     .......     .l0XXXXXXXXXXXXXXXKx,      .....      ..;:::::::::,.   :XMMM
MMMMk.   .::::::::::::;'.',;:::::::;'.    :0XXXXXXXXXXXXXKl.    .,;:::::;,..    .;:::::::::.   .kMMM
MMMWl    ':::::::::::::::::::::::::::;.    lXXXXXXXXXXXXXd.   .;::::::::::::,...,::::::::::'    ;KMM
MMXl.    ,::::::::::::::::::::::::::::;.   ;0XXXXXXXXXXXK:   .,::::::::::::::::::::::::::::,     .dN
WO,      ,::::::::::::::::::::::::::::,.   :KXXXXXXXXXXXKc    '::::::::::::::::::::::::::::,       ;
o.       ':::::::::::::::::::::::::::;.   .dXXXXXXXXXXXXXk'    ':::::::::::::::::::::::::::'        
    .    '::::::::::::::::::::::::::;.    lKXXXXXXXXXXXXXXk,    .,:::::::::::::::::::::::::'   .:;  
  .ox.   .::::::::::::::::::::::::;.    .lKXXXXXXXXXXXXXXXX0l.    .',::::::::::::::::::::::.   'kKd.
 ,kX0;   .;::::::::::::::::::::;'.     ,xKXXXXXXXXXXXXXXXXXXXOc.     ..,;:::::::::::::::::,.   ;KXXO
l0XXXl    ':::::::::::::::;,'..     .;dKXXXXXXXXXXXXXXXXXXXXXXX0o;.      ..',;::::::::::::'   .oXXXX
XXXXXk.   .;;;;;;,,,''....       .,lkKXXXXXXXXXXXXXXXXXXXXXXXXXXXXOd:'.       ....',,;;::;.   'OXXXX
XXXXXKc     ...             ..,cdOKXXXXXXXXXKOxdolllllloxk0KXXXXXXXXXKkoc,..          ....    lXXXXX
XXXXXXO,            ...';cldk0XXXXXXXXX0koc,..           ..,cdOKXXXXXXXXXX0kdlc;'..          ;OXXXXX
XXXXXXX0xollllooddxkO0KKXXXXXXXXXXX0xl;.        .......       .,lxKXXXXXXXXXXXXXK0Okdollcccox0XXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKko;.      ..',;ccllllllc:,'.      ':d0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXX0ko:.      ..,:cooooooooooooooool:;..     .;okKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXKOxl;.      ..,:looooooooooooooooooooooool;'.     .'cdOXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXX0kdc,.      ..,:coooooollcc::;;;;;;;::ccllooooool:,.      .;lx0XXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXKkdl;..      ..,:cooolc:;,'....              ...',:clooolc;'.      .:okKXXXXXXXXXXXXXXX
XXXXXXXXXXKx:..        ..,:cllc;,'..            .....            .',:loool:,..     .':dOKXXXXXXXXXXX
XXXXXXXXXXk'                ..        ..',::clooddddddollc:,'.       .',;;;,,..        .;kXXXXXXXXXX
XXXXXXXXXXKd;''...               .,:codxkkkkkkkkkkkkkkkkkkkkkxoc;'.                     .dKXXXXXXXXX
XXXXXXXXXXXXXKKK0kl,.       .,:loxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdl:'.           ':llodkKXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXKOo:.      .,:lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdc'.      'ckKXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0xc,.      .';:loxkkkkkkkkkkkkkkkkkkkkkkkxoc;'.      'cx0XXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXKOdc,.        ..,;::cllooooooollc::;'..       .;lkKXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0koc,..                             .':lx0XXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0Oxol:,'...           ...';:loxOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK00OkxxxxddxxxkO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

                             Art provided by: Bellus Auctor|Isekai#8224                             
*/

/// @title ERC721 for Isekai Meta
/// @author @ItsCuzzo & @frankied_eth

contract IsekaiMeta is IIsekaiMeta, Ownable, ERC721A {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        RAFFLE,
        SUMMON,
        PUBLIC
    }

    SaleStates public saleState;

    address private _signer;
    string private _baseTokenURI;

    uint256 public constant RESERVED_TOKENS = 100;
    uint256 public constant WALLET_LIMIT = 2;

    uint256 public maxSupply = 10000;
    uint256 public raffleSupply = 6800;
    uint256 public summonCost = 0.15 ether;
    uint256 public publicCost = 0.25 ether;

    mapping(address => uint256) public teamClaim;

    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleStates saleState);

    modifier checkState(SaleStates saleState_) {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    constructor(address receiver) ERC721A("Isekai Meta", "ISEKAI") {
        _mintERC2309(receiver, RESERVED_TOKENS);
    }

    /// @notice Function used to mint tokens during the `RAFFLE` sale state.
    function raffleMint(uint256 quantity, bytes calldata signature)
        external
        payable
        checkState(SaleStates.RAFFLE)
    {
        if (msg.value != quantity * publicCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > WALLET_LIMIT)
            revert WalletLimitExceeded();
        if (_totalMinted() + quantity > raffleSupply) revert SupplyExceeded();
        if (!_verifySignature(signature, "RAFFLE")) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens during the `SUMMON` sale state.
    function summonMint(bytes calldata signature)
        external
        payable
        checkState(SaleStates.SUMMON)
    {
        if (msg.value != summonCost) revert InvalidEtherAmount();
        if (_totalMinted() + 1 > maxSupply) revert SupplyExceeded();
        if (_getAux(msg.sender) != 0) revert TokenClaimed();
        if (!_verifySignature(signature, "SUMMON")) revert InvalidSignature();

        /// @dev Set non-zero auxilary value to acknowledge that the caller has claimed their token.
        _setAux(msg.sender, 1);

        _mint(msg.sender, 1);

        emit Minted(msg.sender, 1);
    }

    /// @notice Function used to mint tokens during the `PUBLIC` sale state.
    function publicMint(uint256 quantity, bytes calldata signature)
        external
        payable
        checkState(SaleStates.PUBLIC)
    {
        if (msg.value != quantity * publicCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > WALLET_LIMIT)
            revert WalletLimitExceeded();
        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();
        if (!_verifySignature(signature, "PUBLIC")) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used by team members to claim their allocated tokens.
    /// @dev Forces team members to claim all of their allocated tokens at once.
    /// If a user has an invalid value (0) in the `teamClaim` mapping, call will
    /// revert within `_mint`. All team members will claim their tokens prior to
    /// the initiation of `summonMint`. Otherwise, they may be unable to claim.
    function teamMint() external {
        uint256 quantity = teamClaim[msg.sender];

        /// @dev Reset value to 0 for gas refund.
        delete teamClaim[msg.sender];

        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens free of charge.
    function ownerMint(address receiver, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > maxSupply) revert SupplyExceeded();

        _mint(receiver, quantity);
    }

    /// @notice Function used to set a new `_signer` value.
    /// @param newSigner Newly desired `_signer` value.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to change the current `saleState` value.
    /// @param newSaleState The new `saleState` value.
    /// @dev 0 = CLOSED, 1 = RAFFLE, 2 = SUMMON, 3 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC))
            revert InvalidSaleState();

        saleState = SaleStates(newSaleState);

        emit SaleStateChanged(saleState);
    }

    /// @notice Function used to set the amount of tokens a team member can claim.
    function setTeamClaim(
        address[] calldata members,
        uint256[] calldata quantitys
    ) external onlyOwner {
        if (members.length != quantitys.length) revert ArrayLengthMismatch();

        address member;
        uint256 quantity;

        unchecked {
            for (uint256 i = 0; i < members.length; i++) {
                member = members[i];
                quantity = quantitys[i];

                teamClaim[member] = quantity;
            }
        }
    }

    /// @notice Function used to check the number of tokens `account` has minted.
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /// @notice Function used to check if `account` has claimed a SL token.
    /// @return Returns a boolean value that indicates whether or not `account`
    /// has claimed a token from `summonMint`.
    function summonClaimed(address account) external view returns (bool) {
        return _getAux(account) == 1 ? true : false;
    }

    /// @notice Function used to view the current `_signer` value.
    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to set a new `maxSupply` value.
    /// @param amount Newly intended `maxSupply` value.
    /// @dev No more than 10,000 tokens, EVER!
    function setMaxSupply(uint256 amount) external onlyOwner {
        if (amount > 10000) revert InvalidTokenCap();
        maxSupply = amount;
    }

    /// @notice Function used to set a new `raffleSupply` value.
    /// @param amount Newly intended `raffleSupply` value.
    function setRaffleSupply(uint256 amount) external onlyOwner {
        if (amount > 6800) revert InvalidTokenCap();
        raffleSupply = amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        if (!success) revert WithdrawFailed();
    }

    function changePublicPrice(uint256 newPrice) external onlyOwner {
        publicCost = newPrice;
    }

    function changeSummonPrice(uint256 newPrice) external onlyOwner {
        summonCost = newPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _verifySignature(bytes memory signature, string memory phase)
        internal
        view
        returns (bool)
    {
        return
            _signer ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, phase))
                )
            ).recover(signature);
    }
}
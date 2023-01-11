//SPDX-License-Identifier: MIT

//   █    ██  ███▄    █ ▓█████▄ ▓█████ ▄▄▄      ▓█████▄     ▄▄▄       ██▀███  ▄▄▄█████▓
//   ██  ▓██▒ ██ ▀█   █ ▒██▀ ██▌▓█   ▀▒████▄    ▒██▀ ██▌   ▒████▄    ▓██ ▒ ██▒▓  ██▒ ▓▒
//  ▓██  ▒██░▓██  ▀█ ██▒░██   █▌▒███  ▒██  ▀█▄  ░██   █▌   ▒██  ▀█▄  ▓██ ░▄█ ▒▒ ▓██░ ▒░
//  ▓▓█  ░██░▓██▒  ▐▌██▒░▓█▄   ▌▒▓█  ▄░██▄▄▄▄██ ░▓█▄   ▌   ░██▄▄▄▄██ ▒██▀▀█▄  ░ ▓██▓ ░ 
//  ▒▒█████▓ ▒██░   ▓██░░▒████▓ ░▒████▒▓█   ▓██▒░▒████▓     ▓█   ▓██▒░██▓ ▒██▒  ▒██▒ ░ 
//  ░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒  ▒▒▓  ▒ ░░ ▒░ ░▒▒   ▓▒█░ ▒▒▓  ▒     ▒▒   ▓▒█░░ ▒▓ ░▒▓░  ▒ ░░   
//  ░░▒░ ░ ░ ░ ░░   ░ ▒░ ░ ▒  ▒  ░ ░  ░ ▒   ▒▒ ░ ░ ▒  ▒      ▒   ▒▒ ░  ░▒ ░ ▒░    ░    
//   ░░░ ░ ░    ░   ░ ░  ░ ░  ░    ░    ░   ▒    ░ ░  ░      ░   ▒     ░░   ░   ░      
//     ░              ░    ░       ░  ░     ░  ░   ░             ░  ░   ░              
//                       ░                       ░                                     

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";

contract UndeadArt is
    ERC721A("Undead Art", "UA"),
    ERC721AQueryable,
    Ownable,
    DefaultOperatorFilterer
{
    enum FateStatus {
        DEAD,
        UNDEAD_PACT,
        UNDEAD_RISE
    }

    // ------------------------------------------------------------------------
    // * Storage
    // ------------------------------------------------------------------------

    uint256 public maxRisenUndead = 9999;
    uint256 public maxPactWithUndead = 9000;
    
    uint256 public soulCost = 0.005 ether;
    uint256 public pactCost = 0.003 ether;

    uint256 public freeUndeadPerCrypt = 1;
    uint256 public maxUndeadPerCrypt = 3;

    FateStatus public fateStatus;
    bytes32 public pact;
    string public soulBind;

    // ------------------------------------------------------------------------
    // * Modifiers
    // ------------------------------------------------------------------------

    modifier soulCostCompliance(uint256 headcount, bool isForPact) {
        uint256 risen = _numberMinted(msg.sender);
        uint256 freeUndead = headcount - 1;
        uint256 freeUndeadLeft = freeUndeadPerCrypt > risen ? freeUndeadPerCrypt - risen : 0;
        uint256 paidCount = headcount > freeUndeadLeft ? headcount - freeUndeadLeft : 0;
        uint256 currentSoulCost = isForPact ? pactCost : soulCost;
        uint256 totalSoulCost = isForPact ? paidCount * currentSoulCost : headcount == maxUndeadPerCrypt ? freeUndead * currentSoulCost : headcount * currentSoulCost;
        require(msg.value >= totalSoulCost, "Not enough soul essence to fuel the Undead");
        _;
    }

    modifier riseCompliance(uint256 headcount, bool isForPact) {
        uint256 currentUndeadLeft = isForPact ? maxPactWithUndead : maxRisenUndead;
        require(tx.origin == msg.sender, "You are not human, we need human blood");
        require(totalSupply() + headcount <= currentUndeadLeft, "All undead have risen");
        require(
            _numberMinted(msg.sender) + headcount <= maxUndeadPerCrypt,
            "Too many undead in your crypt"
        );
        _;
    }

    // ------------------------------------------------------------------------
    // * Frontend view helpers
    // ------------------------------------------------------------------------

    function getResurrectedUndead(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    // ------------------------------------------------------------------------
    // * Mint
    // ------------------------------------------------------------------------

    function undeadRise(
        uint256 headcount
    ) external payable soulCostCompliance(headcount, false) riseCompliance(headcount, false) {
        require(
            fateStatus == FateStatus.UNDEAD_RISE,
            "Undead Rise has not yet been unleashed upon the living"
        );
        _mint(msg.sender, headcount);
    }

    function undeadPact(
        uint256 headcount,
        bytes32[] memory bloodyPact
    ) external payable soulCostCompliance(headcount, true) riseCompliance(headcount, true) {
        require(
            fateStatus == FateStatus.UNDEAD_PACT ||
                fateStatus == FateStatus.UNDEAD_RISE,
            "Pact with the Undead has not yet been sealed in blood"
        );
        require(
            MerkleProof.verify(bloodyPact, pact, keccak256(abi.encodePacked(msg.sender))),
            "Not etched in the pact with the undead. Your blood is not worthy."
        );
        _mint(msg.sender, headcount);
    }

    // ------------------------------------------------------------------------
    // * Admin Functions
    // ------------------------------------------------------------------------

    function necromancerMint(uint256 headcount, address to) external onlyOwner {
        require(headcount + totalSupply() <= maxRisenUndead, "All undead have risen");
        _safeMint(to, headcount);
    }

    function bindUndead(string memory bind) external onlyOwner {
        soulBind = bind;
    }

    function setFate(FateStatus fate) external onlyOwner {
        fateStatus = fate;
    }

    function setPact(bytes32 newPact) external onlyOwner {
        pact = newPact;
    }

    function soulDrain() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Soul drain failed");
    }

    function burnLostSouls(uint256 newRisen, uint256 newPact) external onlyOwner {
        maxRisenUndead = newRisen;
        maxPactWithUndead = newPact;
    }

    // ------------------------------------------------------------------------
    // * Operator Filterer Overrides
    // ------------------------------------------------------------------------

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ------------------------------------------------------------------------
    // * Internal Overrides
    // ------------------------------------------------------------------------

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return soulBind;
    }
}